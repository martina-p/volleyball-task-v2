 %% PTB parameters

    % Screen Preferences
    Screen('Preference', 'VBLTimestampingMode', 3);%Add this to avoid timestamping problems
    Screen('Preference', 'DefaultFontName', 'Geneva');
    Screen('Preference', 'DefaultFontSize', 20); %fontsize
    Screen('Preference', 'DefaultFontStyle', 0); % 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend,1+2=bold and italic.
    Screen('Preference', 'DefaultTextYPositionIsBaseline', 1); % align text on a line 
    
    % Colors definition
    white = [255 255 255]; 
    black = [0 0 0]; 
    red = [255 0 0];
    grey = [150 150 150];
    
    % Keyboard parameters
    KbName('UnifyKeyNames');
    keyLeft=KbName('leftArrow');
    keyRight=KbName('rightArrow');
    
    % Start PTB
    screens=Screen('Screens');
    Screen('Preference', 'SkipSyncTests', 2);
    screenNumber=max(screens); % Main screen
    [win,winRect] = Screen('OpenWindow',screenNumber,black);
    HideCursor;
    
%% Load instruction slides
    
    slide1=imread(fullfile('Stimfiles', 'Slide1.bmp')); 
    texslide1 = Screen('MakeTexture', win, slide1);
    
%% Load stimuli

    Lose=imread(fullfile('Stimfiles', 'Lose.png')); 
    texLose = Screen('MakeTexture', win, Lose);
    Win=imread(fullfile('Stimfiles', 'Win.png')); 
    texWin = Screen('MakeTexture', win, Win);
    Play=imread(fullfile('Stimfiles', 'with.png')); 
    texPlay = Screen('MakeTexture', win, Play);
    Pause=imread(fullfile('Stimfiles', 'without.png')); 
    texPause = Screen('MakeTexture', win, Pause);
    
%% Stimuli size & positions 
    %Play
    [imageHeight, imageWidth, colorChannels] = size(Play);
    imagePlay = [0 0 imageWidth imageHeight];
    
    %Pause
    [imageHeight, imageWidth, colorChannels] = size(Pause);
    imagePause = [0 0 imageWidth imageHeight];
    
    %Win
    [imageHeight, imageWidth, colorChannels] = size(Win);
    imageWin = [0 0 imageWidth./10 imageHeight./10];
    
    %Lose
    [imageHeight, imageWidth, colorChannels] = size(Win);
    imageLose = [0 0 imageWidth./10 imageHeight./10];
    
    %xc = winRect(3)/2;
    %yc = winRect(4)/2;
    [xc, yc] = RectCenterd(winRect);    %get center coordinates
    xcOffsetLeft = xc-230;              %position left image
    xcOffsetRight = xc+130;             %position right image

    %Play on the left, Pause on the right
    imageRectPlayLeft = [xcOffsetLeft, yc, xcOffsetLeft+(imagePlay(:,3)), yc+(imagePlay(:,4))];
    imageRectPauseRight = [xcOffsetRight, yc, xcOffsetRight+(imagePause(:,3)), yc+(imagePause(:,4))];
    
    %Pause on the left, Play on the right
    imageRectPlayRight = [xcOffsetRight, yc, xcOffsetRight+(imagePlay(:,3)), yc+(imagePlay(:,4))];
    imageRectPauseLeft = [xcOffsetLeft, yc, xcOffsetLeft+(imagePause(:,3)), yc+(imagePause(:,4))];

    %Win Center position
    imageWin = [xc, yc, xc+imageWin(:,3), yc+imageWin(:,4)]; 
    
    %Lose Center position
    imageLose = [xc, yc, xc+imageLose(:,3), yc+imageLose(:,4)];
    
    %Fixation cross
    crossLength=10;
    crossColor=white;
    crossWidth=3;
    crossLines=[-crossLength, 0; crossLength, 0; 0, -crossLength; 0, crossLength];
    crossLines=crossLines';