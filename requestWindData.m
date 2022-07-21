function [outputdata,id, pressdata] = requestWindData(lat, lon, t_launch)
% REQUESTWINDDATA  Download the best wind data for a launch.
%   Downloads NOAA Ready text output for a given latitude, longitude, and
%   launch time. Only works for times in the near (0-240 hrs) future.
%
%   `lat` and `lon` are coordinates in decimal
%   `t_launch` is the launch time in UTC as a datettime
%       (e.g. `datetime(2021,3,24,20,40,0)`)
%   `outputDir` is where the Ready text file is saved

%% Get a User ID
url = 'https://www.ready.noaa.gov/ready2-bin/main.pl';
data = 'userid=&map=WORLD&newloc=1&WMO=&city=Or+choose+a+city&Lat=30&Lon=-120'; % Doesn't matter what this is requesting
page = webwrite(url,data);
userid = getProp(page, 'userid');

%% Check models
% models to check, in order of preference
models(1) = struct('ID',"HRRRP|HRRRP", 'Description',"HRRR Model (3 km, 18h, 1hrly, CONUS, pressure)");
models(2) = struct('ID',"NAM%2B4%2BCONUS|NAM4CONUS", 'Description',"NAM Model (3km, 48h, 1hrly, CONUS, pressure-sigma hybrid)");
models(3) = struct('ID',"NAM%2B12%2Bkm|NAM12", 'Description',"NAM Model (12km, 84h, 3hrly, CONUS, pressure)");
models(4) = struct('ID',"GFS|GFS", 'Description',"GFS Model (1 degree, 0-240h, 3hrly, Global, pressure)");
models(5) = struct('ID',"GFSlr|GFSlr", 'Description',"GFS Model (1 degree, 240-384h, 12hrly, Global, pressure");

for model = models
    % Get the newest release
    url = 'https://www.ready.noaa.gov/ready2-bin/metcycle.pl';
    data = sprintf('m=%s&product=profile1&userid=%s&Lat=%.2f&Lon=%.2f&x=-1&y=-1&sid=&elev=&sname=&state=&cntry=&map=WORLD',model.ID,userid,lat,lon);
    page = webwrite(url,data);
    % and update metext, mdatacfg, metdata
    ids = regexp(page,'option value="([0-9\s])*">([0-9 UTC/]*) ','tokens');
    metcyc = ids{1}{1};
    metcycstr = ids{1}{2};
    metext = getProp(page,'metext');
    mdatacfg = getProp(page,'mdatacfg');
    metdata = getProp(page,'metdata');
    
    % Check times available
    url = 'https://www.ready.noaa.gov/ready2-bin/profile1.pl';
    data = sprintf('userid=%s&metdata=%s&mdatacfg=%s&Lat=%.2f&Lon=%.2f&sid=&elev=&sname=&state=&cntry=&map=WORLD&x=-1&y=-1&metext=%s&m=%s&metcyc=%s',...
                   userid,metdata,mdatacfg,lat,lon,metext,model.ID,metcyc);
    page = webwrite(url,data);
    dates = [];
    datestrings = [];
    for str = regexp(page,'<option value="([a-zA-Z0-9,\s]*)( UTC.*)','tokens','dotexceptnewline')
%         parseable = erase(str{1}{1},["at "]);
        dates = [dates datetime(str{1}{1},'InputFormat','MMMM dd, yyyy ''at'' HH')];
        datestrings = [datestrings convertCharsToStrings(strcat(str{1}{1}, str{1}{2}))];
    end
    % then pick the closest if it's close enough
    dur = abs(dates(1)-dates(2));
    if t_launch <= max(dates) + dur
        [~,i] = min(abs(dates-t_launch));
        t_model = dates(i);
        datestring = datestrings(i);
        fprintf("Launch time (UTC): %s\nModel time (UTC): %s\nModel: %s generated at %s\n",...
                char(t_launch),datestring,model.Description,metcycstr)
        break
    elseif model.ID == models(end).ID
        error("Error: No wind data available for launch time.")
    end
end

%% OCR Captcha hacking
for tries = 1:10
    imgdir = regexp(page,'<img src="(.*gif)" ALT="Security Code"','tokens','dotexceptnewline');
    imgdir = imgdir{1}{1};

    cap = double(imread("https://www.ready.noaa.gov/"+imgdir));
    nl = cap(min(cap,[],2)<2,min(cap,[],1)<2);
    nl = nl(1:end-mod(size(nl,1),2),1:end-mod(size(nl,2),2)); % resize
    cas(:,:,1) = nl(1:2:end,1:2:end); % magic
    cas(:,:,2) = nl(1:2:end,2:2:end);
    cas(:,:,3) = nl(2:2:end,1:2:end);
    cas(:,:,4) = nl(2:2:end,2:2:end);
    res = ocr(sum(cas,3));
    % imshow(sum(cas,3));
    captcha = res.Text(regexp(res.Text,"[A-Z0-9]"));

    %% Download text
    url = 'https://www.ready.noaa.gov/ready2-bin/profile2.pl';
    metdir = getProp(page,'metdir');
    metfil = getProp(page,'metfil');
    data = strcat(data, sprintf('&metdir=%s&metfil=%s&metdate=%s&type=0&nhrs=24&hgt=0&textonly=Yes&skewt=1&gsize=96&pdf=No&password1=%s&proc=4273',...
                          metdir,metfil,datestring,captcha));
    page = webwrite(url,data);

    txtdir = regexp(page,'<a href="(.*)" target=_blank"><strong>Text Results</strong></a>','tokens','dotexceptnewline');
    try
        txtdir = txtdir{1}{1};
        break
    catch
        fprintf("Captcha failed, trying again...\n")
        url = 'https://www.ready.noaa.gov/ready2-bin/profile1.pl';
        data = sprintf('userid=%s&metdata=%s&mdatacfg=%s&Lat=%.2f&Lon=%.2f&sid=&elev=&sname=&state=&cntry=&map=WORLD&x=-1&y=-1&metext=%s&m=%s&metcyc=%s',...
                   userid,metdata,mdatacfg,lat,lon,metext,model.ID,metcyc);
        page = webwrite(url,data);
    end
end

outputdata = urlread(strcat("https://www.ready.noaa.gov",txtdir));
id = strcat(mdatacfg,'_AT',strrep(metcyc,' ','+'),'_FOR',datestr(t_model,'mmddThhMM'));

% Pull Pressure Data and Export to Table
rawPressure = regexp(page,'PRESS(.+?)hysplit', 'match');
rawPressure = erase(rawPressure{1,1},'hysplit');
pressdata=split(rawPressure);
pressdata([5:6,9:20, end]) = [];
%pressdata = reshape(pressdata, [6,38]);
pressdata([2,3,4,5,6],:) = [];
pressdata{1,1} = 'Pressure';


%% For grabbing basic properties
function pval = getProp(page, prop)
    pval = regexp(page,strcat('<input type="HIDDEN" name="',prop,'" value="(.*)">'),'tokens','dotexceptnewline');
    pval = pval{1}{1};
end

end