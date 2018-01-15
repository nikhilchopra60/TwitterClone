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
  def main(args) do

    serverIP=Enum.at(args, 0)
    {serverNode,clientNode}=setup_client(serverIP)
    UserService.startNewUserService(serverNode,clientNode)
    infiniteLoop()
  end 




  def mainMethod(serverNode,clientNode) do
    
        {:ok, pid} = GenServer.start_link(__MODULE__,{[],[]}, name: :"first")
        {:ok, pid1} = GenServer.start_link(__MODULE__,{[],[]}, name: :"second")
        {:ok, pid1} = GenServer.start_link(__MODULE__,{[],[]}, name: :"third")
    
        IO.puts "Inside Twitter Cclient"
        GenServer.cast({:worker, serverNode}, {:RegisterNewUser, "first", "Kanika Gupta", "Kani"})
        IO.puts "first user registerd"
        GenServer.cast({:worker, serverNode}, {:RegisterNewUser, "second", "Nikhil Chopra", "Nikku"})
        IO.puts "second user registeredd"
    
        GenServer.cast({:worker, serverNode}, {:RegisterNewUser, "third", "Nik Chops", "nakes"})
        IO.puts "third user registeredd"
    
        GenServer.call({:worker, serverNode}, {:LoginRequest, "first"})
        IO.puts "logined first user"
    
        GenServer.call({:worker, serverNode}, {:LoginRequest, "second"})
        IO.puts "logdedd in second user"
        
        GenServer.call({:worker, serverNode}, {:LoginRequest, "third"})
        IO.puts "logdedd in third user"
    
    
        GenServer.cast({:worker, serverNode}, {:FollowRequest, "second", "first"})
        Process.sleep(1000)
        IO.puts "followed"
    
        GenServer.cast({:worker, serverNode}, {:FollowRequest, "third", "second"})
        Process.sleep(1000)
        IO.puts "followed"
        
        #GenServer.cast(:worker, {:TweetRequest, "first", "I am new to twitter. It sucks"})
        #IO.puts "tweeted"
    
        GenServer.cast({:worker, serverNode}, {:TweetRequest, clientNode,"first", "hello @third gudbye"})
        IO.puts "tweeted with mentioned"
    
    
        GenServer.cast({:worker, serverNode}, {:ReTweetRequest, clientNode,"second", "hello @third gudbye"})
        IO.puts "Retweeted "
    
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
    
  



  def setup_client(input) do 
    unless Node.alive?() do
      local_node_name = generate_name_client("client")
      {:ok, _} = Node.start(local_node_name)
    end
    #cookie = Application.get_env("server", :cookie)
    Node.set_cookie(:"Server-cookie")
    serverNode=String.to_atom("server@#{input}")
    Node.connect(serverNode)
    IO.puts "Client connected to Server IP #{input}"
    {serverNode,local_node_name}
  end 

  def generate_name_client(appname) do
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
    hex = :erlang.monotonic_time() |>
      :erlang.phash2(256) |>
      Integer.to_string(16)
    IO.puts "Client started with IP Address: #{ip}"  
    #String.to_atom("#{appname}-#{hex}@#{machine}")
    String.to_atom("#{appname}-#{hex}@#{ip}")
  end


  def infiniteLoop() do
    infiniteLoop()
  end

end
