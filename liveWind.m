temp = 'Temporary/tempwinddata.txt';
[data,id, pressdata] = requestWindData(34,-106,'22-July-2022');
fileID = fopen('data.txt','w');
fprintf(fileID,data);
fclose(fileID);
outputfile = 'test.txt';
tabulateWind('data.txt',pressdata,'test.txt')