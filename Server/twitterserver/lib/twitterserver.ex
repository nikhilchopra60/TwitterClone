defmodule Twitterserver do
  use GenServer
  @moduledoc """
  Documentation for Twitterserver.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Twitterserver.hello
      :world

  """
  def main(args) do
    setup_server()
    UserData.startUserDatabaseActor();
    FollowerData.startFollowerListActor();
    FollowingData.startFollowingListActor();
    Tweets.startTweetActor();
    UserTimeLineData.startUserTimelineActor();
    NewsFeedData.startNewsFeedActor();
    ActiveUserData.startActiveUsersActor();
    UserMentionsData.startUserMentionActor();
    HashTagData.startHashTagActor();
    StatsService.startStatService();
    startServerWorker()
    
    #Twitterclient.mainMethod()
    infiniteLoop()
  end
  
  
  def setup_server() do
    unless Node.alive?() do
      local_node_name = generate_name_server("server")
      {:ok, _} = Node.start(local_node_name)
    end
    Node.set_cookie(:"Server-cookie")
    IO.puts "Server Started"
  end

  def generate_name_server(appname) do
    {:ok,host}= :inet.gethostname
    {:ok,{a,b,c,d}} = :inet.getaddr(host, :inet)
    if a==127 do 
      {:ok, list_ips} = :inet.getif()
      ip=list_ips
      |> Enum.at(0) 
      |> elem(0) 
      |> :inet_parse.ntoa 
      |> IO.iodata_to_binary
    else
      ip=Integer.to_string(a)<>"."<>Integer.to_string(b)<>"."<>Integer.to_string(c)<>"."<>Integer.to_string(d)
    end
    
      IO.puts "Server IP #{ip}"
    String.to_atom("#{appname}@#{ip}")
  end

  def parseTweet(tweetId, tweet) do
    hashTagRegex =  ~r(\B#[a-zA-Z1-9]+\b)
    listOfHashTags = Regex.scan(hashTagRegex, tweet)
    listOfHashTags = List.flatten(listOfHashTags)

    userMentionsRegex =  ~r(\B@[a-zA-Z1-9]+\b)
    listOfUserMentions = Regex.scan(userMentionsRegex, tweet)
    listOfUserMentions = List.flatten(listOfUserMentions)
    mentionedUserList=Enum.map(listOfUserMentions,fn(x)-> String.slice(x,1..String.length(x)) end)

    if length(listOfHashTags) > 0 do
      Enum.each(listOfHashTags, fn(x) -> 
        GenServer.cast(:hashTags, {:AddHashTag, x, tweetId})
      end)
    end

    if length(mentionedUserList) > 0 do
      Enum.each(mentionedUserList, fn(x) ->
        GenServer.cast(:userMentions, {:AddUserMention, x, tweetId})
      end)
    end

    mentionedUserList
  end

  def sendTweetsToUsers(userList, tweet, tweetId,clientNode) do
    
    Enum.each(userList, fn (x) -> 
      result = GenServer.call(:activeUsers, {:checkIfActive, x})

      if result do
        #IO.puts "User is active" <> x
        nodeAtom = String.to_atom(x)
        #IO.inspect nodeAtom 
        #IO.puts "sending tweet to live user"
        GenServer.cast({nodeAtom,clientNode}, {:sendTweetToLiveUser, tweet})
      end
      GenServer.cast(:newsFeed, {:AddTweetToNewsFeed,x,tweetId})
    end)

  end

  def startServerWorker() do
    {:ok, pid} = GenServer.start_link(__MODULE__,[], name: :worker )
  end

  def handle_cast({:ReTweetRequest,clientNode,userName,tweet},state) do
    
    ##Add tweet to tweet table
    tweetId = GenServer.call(:tweets, {:PutTweet, tweet})

    ## Add tweet to user's timeline
    GenServer.cast(:userTimeLine, {:AddTweetToUserTimeLine,userName,tweetId})
    ## Add tweet to user's news Feed
    GenServer.cast(:newsFeed, {:AddTweetToNewsFeed,userName,tweetId})
    #IO.puts "Pushing tweet to self " <> userName
    nodeAtom = String.to_atom(userName)
    #IO.puts nodeAtom
    #IO.puts "sending tweet to self"
    GenServer.cast({nodeAtom,clientNode}, {:sendTweetToLiveUser, tweet})
    followerList = GenServer.call(:followers, {:GetFollowerList,userName})
    #IO.puts "printing follower list of " <> userName <> " fetchced from DB"
    #IO.inspect followerList

    #IO.puts "sending tweet to followers"
    #IO.inspect followerList
    sendTweetsToUsers(followerList, tweet, tweetId,clientNode)
    {:noreply,state}
  end




  def handle_cast({:TweetRequest,clientNode,userName,tweet},state) do
    #IO.puts "TweetRequest user ="<>userName
    #IO.puts "Server got the tweet request"

    ##Add tweet to tweet table
    tweetId = GenServer.call(:tweets, {:PutTweet, tweet})

    mentionedUsersList = parseTweet(tweetId, tweet)
    ## Add tweet to user's timeline
    GenServer.cast(:userTimeLine, {:AddTweetToUserTimeLine,userName,tweetId})
    ## Add tweet to user's news Feed
    GenServer.cast(:newsFeed, {:AddTweetToNewsFeed,userName,tweetId})


    #IO.puts "Pushing tweet to self " <> userName
    userAtom = String.to_atom(userName)
    #IO.puts userAtom
    #IO.puts "sending tweet to self"
    GenServer.cast({userAtom,clientNode}, {:sendTweetToLiveUser, tweet})


    followerList = GenServer.call(:followers, {:GetFollowerList,userName})
    #IO.puts "printing follower list of " <> userName <> " fetchced from DB"
    #IO.inspect followerList

    #IO.puts "sending tweet to followers"
    #IO.inspect followerList
    sendTweetsToUsers(followerList, tweet, tweetId,clientNode)


    #IO.puts "sending tweet to mentioned"
    #IO.inspect mentionedUsersList

    if length(mentionedUsersList) > 0 do
       sendTweetsToUsers(mentionedUsersList, tweet, tweetId,clientNode)
    end
    
    {:noreply,state}
  end

  def handle_call({:GetMentions, userName}, _from,state) do
    mentionsTweetIdList=GenServer.call(:userMentions, {:GetTweetsForMentionedUser,userName})
    mentionsTweetList = Enum.map(mentionsTweetIdList, fn(x) ->
      GenServer.call(:tweets, {:GetTweetById, x})
    end)

    {:reply,mentionsTweetList,state}
  end

  def handle_call({:GetHashTags, hashTag}, _from,state) do
    hashTagTweetIDList=GenServer.call(:hashTags, {:GetTweetsForHashTag,hashTag})
    

    hashTagTweetList = Enum.map(hashTagTweetIDList, fn(x) ->
      GenServer.call(:tweets, {:GetTweetById, x})
    end)

    {:reply,hashTagTweetList,state}
  end

  def handle_cast({:FollowRequest, userName, followUserName}, state) do
    #IO.puts userName<>" user is following "<> followUserName
    GenServer.cast(:followers, {:AddFollowerToUser,followUserName,userName})
    GenServer.cast(:followings, {:AddFollowingToUser,userName,followUserName})
    
    {:noreply,state}
  end

  def handle_cast({:RemoveFollowRequest, userName, followUserName}, state) do
    
    GenServer.cast(:followers, {:AddFollowerToUser,followUserName,userName})
    GenServer.cast(:followings, {:AddFollowingToUser,userName,followUserName})
    
    {:noreply,state}
  end

  def handle_cast({:RegisterNewUser, userName, fullName, password}, state) do
    #IO.puts "registering user ="<>userName
    GenServer.call(:users, {:registerNewUser, userName, password, fullName})
    ##GenServer.call(:activeUsers,{:incomingActiveUser, userName})
    
    {:noreply,state}
  end
  
  def handle_cast({:LogoutRequest, userName}, state) do
    #IO.puts "logging OUT user ="<>userName
    GenServer.cast(:activeUsers,{:outGoingActiveUser, userName})
    
    {:noreply,state}
  end

  def handle_call({:LoginRequest, userName,password}, _from, state) do
    #IO.puts "logging IN user ="<>userName

    auth = GenServer.call(:users,{:authenticateUser, userName,password})

    if auth == "Valid User" do
      GenServer.call(:activeUsers,{:incomingActiveUser, userName})
      newsfeedTweetIds = GenServer.call(:newsFeed, {:GetRecentNewsFeed,userName})
      userTimeLineTweetIds = GenServer.call(:userTimeLine, {:GetUserTimeLine,userName})
  
      newsFeedTweets = Enum.map(newsfeedTweetIds, fn(x) ->
        GenServer.call(:tweets, {:GetTweetById, x})
      end)
  
      userTimeLineTweets = Enum.map(userTimeLineTweetIds, fn(x) ->
        GenServer.call(:tweets, {:GetTweetById, x})
      end)

    end
    {:reply, {userTimeLineTweets, newsFeedTweets} ,state}
  end

  def infiniteLoop() do
    infiniteLoop()
  end

end
