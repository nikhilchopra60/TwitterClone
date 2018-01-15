** TWITTER CLONE IMPLEMENTATION **

1. Team Members

Kanika Gupta, UFID - 96977046, kanikagupta@ufl.edu
Nikhil Chopra, UFID - 98973831, nikhilchopra60@ufl.edu

2. What is working

Twitter Clone is working with the client simulator.

3. How to run

   a. Start the server 
      Go to - project4part1/Server/twitterserver
      Run Command - escript twitterserver

This will generate twitterserverIP on the terminal.

   b. Start the client 
      Go to - project4part1/Client/twitterclient
      Command - escript twitterclient {twitterserverIP}

4. How to generate results

In order to see the results, press Y and enter on the server to generate zipf_results.csv (Excel file) in the folder project4part1/Server/twitterserver. This file contains number of followers of each user. This file will populate with number of followers corresponding to each user having follower count >= 1. Follow the below steps to generate zipf graph - 

	1. Open zipf_results.csv in MS Excel.
	2. Select column A.
	3. Go to Data in the menu bar and sort the results from Z -> A.
	4. Select column A.
	5. Go to Insert in the menu bar and select Line chart to see the zipf distribution of followers.

5. Largest Number of users simulated

This implementation of twitter clone ran successfully on a network of 10,000 users, with 100% CPU utilization, which were simulated through the client simulator. The following operations were performed by the simulated users simultaneously - tweet, follow, login, logout and retweet.