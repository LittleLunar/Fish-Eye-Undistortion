function main()
fprintf("Raspberry Pi info\n");
ipaddress = input('IP address : ', 's');
username = input('Username : ', 's');
password = input('Password : ', 's');

fprintf("\nConnecting...\n");

mypi = raspi(ipaddress,username,password); 

fprintf("\nConnected to Raspberry Pi...\n");

configurePin(mypi,4,'DigitalInput');

fprintf("\nPrepare images and output directory for you\n");
[~, errmsg1, ~] = mkdir('images');
if errmsg1 ~= ""
    fprintf("images %s\n",errmsg1);
end

[~, errmsg2, ~] = mkdir('output');
if errmsg2 ~= ""
    fprintf("output %s\n",errmsg2);
end

fprintf("Directory created...\n");

image_path = fullfile(getcurrentdir(),'images');

i = int32(1);
fprintf("\nYou're ready to capture images : \n");
while true
    
    if(readDigitalPin(mypi,4) == 0)

        filename = sprintf('image%d.jpg', i);
        save_path = sprintf('/home/pi/Pictures/%s',filename);
        command = sprintf('raspistill -o %s', save_path);

        system(mypi,command);
        
        fprintf("\nCaptured an image\n");

        fprintf("Getting the file, please wait...\n");
        getFile(mypi, save_path,image_path);
        fprintf("Got the file : %s\n", fullfile(image_path, filename));
     
        undistort(filename);

        fprintf("The image is undistorted\n");

        deleteFile(mypi,save_path);
        
        i = i + 1;
    end
end

end


function undistort(distortImageName)


refX = repmat([0,500:300:3200,3700]',5,1);
refY = sort(repmat((10:300:1210)',12,1));
distX = [0, 368, 606, 915, 1263, 1660, 2127, 2565, 2982, 3320, 3609, 4046, 109, 467, 706, 994, 1312, 1710, 2137, 2555, 2933, 3261, 3549, 3976, 209, 567, 795, 1074, 1382, 1760, 2137, 2535, 2873, 3191, 3469, 3897, 298, 656, 885, 1163, 1441, 1819, 2137, 2495, 2813, 3112, 3380, 3817, 418, 765, 984, 1243, 1501, 1849, 2137, 2475, 2774, 3042, 3300, 3718]';
distY = [1123, 1043, 993, 954, 924, 894, 864, 854, 864, 874, 904, 964, 1401, 1371, 1351, 1321, 1321, 1311, 1282, 1262, 1252, 1252, 1262, 1272, 1639, 1639, 1639, 1629, 1649, 1659, 1629, 1619, 1590, 1580, 1560, 1530, 1840, 1870, 1880, 1900, 1930, 1950, 1930, 1910, 1880, 1860, 1830, 1771, 2069, 2099, 2109, 2138, 2158, 2178, 2158, 2148, 2119, 2079, 2059, 1979]';
resolution = [1240 3500 3];

fixedPoints = [refX,refY];
movingPoints = [distX,distY];

dist = imread(fullfile(getcurrentdir(),'images',distortImageName));
tform = fitgeotrans(movingPoints,fixedPoints,'pwl');
registImage = imwarp(dist,tform,'OutputView',imref2d(resolution));
save_path = sprintf("output\\%s", distortImageName );
imwrite(registImage, save_path);

end

function currentDir = getcurrentdir()
if isdeployed % Stand-alone mode.
    [status, result] = system('path');
    currentDir = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
else % MATLAB mode.
    currentDir = pwd;
end
end