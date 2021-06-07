clc;
clear all;
close all;
%Ask the time
%for how many hours will car be parked ?
% time = input("How many hours will you stay (3$ per hour) ? ");
% fee = time*3;
% Read the image
filename = "Plates/plaka6.jpg";
image = imread(filename);
%image = imresize(image,[200 400]);
%imshow(image); %figure1

%Convert image to gray
%Get from RGB to 0-255 black&white image
figure;
image_gray = rgb2gray(image);
%imshow(image_gray); %figure2

%Check the histogram of the image for best threshold value

figure;
histogram(image_gray);

threshold=85;
figure;
imageBW = image_gray < threshold;
imshow(imageBW); % figure3

% Text are white in the image
% We are looking for these white pixels

figure;
WhitePerRow = sum(imageBW,2);
hold on;
plot(WhitePerRow); %figure4
xlabel("Row Number");
ylabel("Number of White Pixels");
legend("White Pixels");
hold off;

% We need the find the region that we interested in which has the text we
% are looking for (Region of Interest)

region = WhitePerRow > 40;
% Our threshold value is 40 where is the white region starts
figure;
plot(1:length(WhitePerRow) , WhitePerRow); %figure5

hold on;

%Multiple the region value which is 1 with 200 to see where are white
plot(region*200);
xlabel("Row Nmber");
ylabel("Number of White Pixels");
legend("White Pixels" , "Regions");
hold off;

%Look at the regions where color changes
figure;
plot(diff(region)); %figure6

region_start = [1; find(diff(region)==1)];

region_end = [find(diff(region)==-1); length(region)];

diff_end_start=region_end-region_start;

[~,widestRegion]=max(diff_end_start);
%Find where the text starts
upperLimitRegion = region_start(widestRegion);

%Find where the text ends
lowerLimitRegion = region_end(widestRegion);

%Crop the image from top and bottom
figure;
LicenseNumberROI = imageBW(upperLimitRegion:lowerLimitRegion,:);
imshow(LicenseNumberROI); %figure7

% Now will look white pixels at each column

whitePerColumn = sum(LicenseNumberROI,1);
hold on;
plot(max(whitePerColumn)-whitePerColumn,'r',"LineWidth",3); % figure8
xlabel("Column Number");
ylabel("Number of White Pixels");
hold off;

% Same steps like rows
region = whitePerColumn > 30;
figure;
plot(whitePerColumn); %figure9

hold on;
plot(region*200);
xlabel("column Number");
ylabel("Number of White Pixels");
legend("White Pixels","Region");
hold off;

figure;
plot(diff(region)); %figure10

region_start = [1 find(diff(region)==1)];

region_end = [find(diff(region)==-1) length(region)];

region = region_end-region_start;

%Find the mean region size.
widththreshold = mean(region);

letterImage = LicenseNumberROI(:,region_start(1):region_end(2)+1);

% figure;
% imshow(letterImage); %figure11

%We need to find which letters match with the letters in the image

templateDir = fullfile('templates');
templates = dir(fullfile(templateDir,'*.png'));

figure;
candidateImage = cell(length(templates),2);
for p=1:length(templates)
    subplot(7,8,p)
    [~,fileName] = fileparts(templates(p).name);
    candidateImage{p,1} = fileName;
    candidateImage{p,2} = imread(fullfile(templates(p).folder,templates(p).name));
    imshow(candidateImage{p,2}); %figure12
end

template1 = imread(fullfile(templates(1).folder,templates(1).name));
% figure;
% imshow(template1); %figure13

%To match the images we need resize them

letterImage = imresize(letterImage,size(template1));
% figure;
% subplot(1,2,1)
% imshow(letterImage);%figure14
% subplot(1,2,2)
% imshow(template1);

distance = zeros(1,length(templates));
for p=1:length(templates)
    distance(p) = abs(sum((letterImage-double(candidateImage{p,2})).^2 ,"all"))/numel(candidateImage{p,2});
end
% figure;
chars = ["0","1","2","3","4","5","6","7","8","9",...
    "A","B","C","D","E","F","G","H","I","J","K","L",...
    "M","N","O","P","Q","R","S","T","U","V","W","X",...
    "Y","Z","0","4","6","6","8","9","9","A","B","D","O","P",...
    "Q","R"];
% plot(distance) %figure15
% xticklabels(chars)
% xticks(1:length(chars))
% xlim([1 50])

[d,idx] = min(distance);

[~,letter] = fileparts(templates(idx).name);

%Now put all together and read the license plate

license_number = '';
for p=1:length(region)
    if region(p) > widththreshold
        %Extract the letter
        letterImage = LicenseNumberROI(:,region_start(p):region_end(p));
        
        %Compare templates
        distance = zeros(1,length(templates));
        for t=1:length(templates)
            letterImage = imresize(letterImage,size(candidateImage{t,2}));
            distance(t) = abs(sum((letterImage-double(candidateImage{t,2})).^2,"all"));
        end
        [d,idx] = min(distance);
        letter = candidateImage{idx,1};
        
        license_number(end+1) = letter;
    end
end

disp(license_number)

% fileID = fopen('Car Plates.txt','w');
% fprintf(fileID,'%7s %2d $',license_number,fee);
% fclose(fileID);

