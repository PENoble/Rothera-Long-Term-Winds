function LocalDataDir = LocalDataDir()

%identifies which machine we're using, and sets the path to the data store directory accordingly
TheComputerThisIsOn = upper(char(java.net.InetAddress.getLocalHost.getHostName));

%set data directory path
if strcmp(TheComputerThisIsOn,'UBMD-1542587') == 1;
  %Dell laptop
  LocalDataDir = 'C:\Users\pn399\OneDrive - University of Bath\';
elseif strcmp(TheComputerThisIsOn,'UBPC-5254') == 1 
  %My uni pC 
 LocalDataDir = 'C:\Users\pn399\OneDrive - University of Bath\';  
elseif strcmp(TheComputerThisIsOn(1:4),'ITD-') == 1 || strcmp(TheComputerThisIsOn(1:5),'NODE-') == 1
  %Balena
  LocalDataDir = '/home/f/cw785/scratch/Data/';
elseif isunix 
  %unix system (assumes on Bath network)
  LocalDataDir = '/u/n/pn399/data/';
else
  %unspecified windows machine (assumes on Bath network)
  LocalDataDir = 'Z:\Data\';
end


return
