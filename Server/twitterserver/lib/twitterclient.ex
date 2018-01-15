defmodule Twitterclient do
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
  def mainMethod() do

    {:ok, pid} = GenServer.start_link(__MODULE__,{[],[]}, name: :"first")
    {:ok, pid1} = GenServer.start_link(__MODULE__,{[],[]}, name: :"second")
    {:ok, pid1} = GenServer.start_link(__MODULE__,{[],[]}, name: :"third")

    IO.puts "Inside Twitter Cclient"
    GenServer.cast(:worker, {:RegisterNewUser, "first", "Kanika Gupta", "Kani"})
    IO.puts "first user registerd"
    GenServer.cast(:worker, {:RegisterNewUser, "second", "Nikhil Chopra", "Nikku"})
    IO.puts "second user registeredd"

    GenServer.cast(:worker, {:RegisterNewUser, "third", "Nik Chops", "nakes"})
    IO.puts "third user registeredd"

    GenServer.call(:worker, {:LoginRequest, "first"})
    IO.puts "logined first user"

    GenServer.call(:worker, {:LoginRequest, "second"})
    IO.puts "logdedd in second user"
    
    GenServer.call(:worker, {:LoginRequest, "third"})
    IO.puts "logdedd in third user"


    GenServer.cast(:worker, {:FollowRequest, "second", "first"})
    Process.sleep(1000)
    IO.puts "followed"

    GenServer.cast(:worker, {:FollowRequest, "third", "second"})
    Process.sleep(1000)
    IO.puts "followed"
    
    #GenServer.cast(:worker, {:TweetRequest, "first", "I am new to twitter. It sucks"})
    #IO.puts "tweeted"

    GenServer.cast(:worker, {:TweetRequest, "first", "hello @third gudbye"})
    IO.puts "tweeted with mentioned"


    GenServer.cast(:worker, {:ReTweetRequest, "second", "hello @third gudbye"})
    IO.puts "Retweeted with mentioned"

    #mentionList=GenServer.call(:worker, {:GetMentions,"third"})
    #IO.puts "getting mentions"
    #IO.inspect mentionList


    #GenServer.cast(:worker, {:TweetRequest, "first", "hello #hellobro gudbye"})
    #IO.puts "tweeted with hashtags"

    #hashTagList=GenServer.call(:worker, {:GetHashTags,"#hellobro"})
    #IO.puts "getting hashtags"
    #IO.inspect hashTagList
    
    infiniteLoop()
  end

  def handle_cast({:sendTweetToLiveUser, tweet}, state) do
    
    {homeTimeLine,newsFeed} = state
    newsFeed = [tweet] ++ newsFeed
    state = {homeTimeLine,newsFeed}
    IO.puts "Inside " <> "got live tweet, adding to my newsfeed tweet = "<> tweet
    IO.inspect self()
    {:noreply, state}

  end


  def infiniteLoop() do
    infiniteLoop()
  end
end
