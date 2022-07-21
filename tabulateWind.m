function [] =  tabulateWind(inputPath, pressdata, outputPath)
%Input is a text file with single quotes around it.

%To get the input file, just right click
%on the sounding data generated and save the entire thing as a .txt file
%in this folder

%Outputs a csv file with name specified in outputPath, example input of
%outputPath = 'AtmosphereData.csv'

%run function >>windFileGenerator('windex4.txt')
%reference example wind file 'windex4' in this folder

%Wind Direction: Degrees
%windSpeed: 0.1m/s
%Altitude: m
data = readcell(inputPath);

data(:,3) = [];
data(:,3) = [];
data(:,3) = [];

rows = length(data(:,1));

%finds the index of the word wind to indicate where wind direction data and wind speed data start
index = find(~cellfun(@isempty,cellfun(@(data) strfind(data,'========Wind'),data,'uniform',0)));

windDirection = [];
altitude = [];
windSpeed = [];

%fills arrays
for i = (index(1)+2) : (index(2) - 1)
    windDirection = [windDirection, data(i,2)];
    altitude = [altitude, data(i,1)];
end

for i = (index(2) + 2) : rows
    windSpeed = [windSpeed, data(i,2)];
end

%first line of altitude data sometimes has a .E at the end, this removes that
%to convert to a matrix
k = altitude(1,1);
if iscellstr(k) == 1
    h = erase(k, '.E');
    h = str2double(h);
    altitude(1,1) = {h};
end


windDirection = cell2mat(windDirection);
windSpeed = cell2mat(windSpeed);
altitude = cell2mat(altitude);

%changes windSpeed from m/s to [0.1 m/s]
windSpeed = windSpeed.*10;


windDirection = ["Wind Direction [deg]", windDirection];
windSpeed = ["Wind Speed [0.1m/s]", windSpeed];
altitude = ["Altitude [m]", altitude];

totalData = [altitude', windDirection', windSpeed'];

writematrix(totalData, outputPath)
