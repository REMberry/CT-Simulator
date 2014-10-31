function varargout = BeamProfile(varargin)
% BEAMPROFILE M-file for BeamProfile.fig
%      BEAMPROFILE, by itself, creates a new BEAMPROFILE or raises the existing
%      singleton*.
%
%      H = BEAMPROFILE returns the handle to a new BEAMPROFILE or the handle to
%      the existing singleton*.
%
%      BEAMPROFILE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BEAMPROFILE.M with the given input arguments.
%
%      BEAMPROFILE('Property','Value',...) creates a new BEAMPROFILE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BeamProfile_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BeamProfile_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BeamProfile

% Last Modified by GUIDE v2.5 05-May-2013 12:38:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BeamProfile_OpeningFcn, ...
                   'gui_OutputFcn',  @BeamProfile_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before BeamProfile is made visible.
function BeamProfile_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BeamProfile (see VARARGIN)

% Choose default command line output for BeamProfile
hSrcImage = varargin{1};
transform = varargin{2};

handles.output = hObject;
handles.image = get(hSrcImage,'CDATA');
handles.max = max(handles.image(:));
handles.ImageSize = size(handles.image);
handles.transform = transform;

XData = get(hSrcImage, 'XDATA');
YData = get(hSrcImage, 'YDATA');
handles.XData = XData;
handles.YData = YData;
handles.YMax = max(YData);
handles.YMin = min(YData);

axes(handles.axesTransformed);
colormap(gray);

imagesc(handles.image, 'XDATA', XData, 'YDATA', YData);
ImageParent=get(hSrcImage, 'Parent');
hLx = get(ImageParent, 'XLabel');
hLy = get(ImageParent, 'YLabel');
xlabel(get(hLx, 'String'));
ylabel(get(hLy, 'String'));

sliderMin = 1;
sliderMax = numel(XData);
% Slider-Schritteweite
%   - an den äußeren Pfeilen mit eingestellter Auflösung
%   - Klick innerhalb des Slider mit 5-facher Auflösung
sliderStep = [1/sliderMax 5/sliderMax];

set(handles.sliderAngle, 'Min', sliderMin);
set(handles.sliderAngle, 'Max', sliderMax);
set(handles.sliderAngle, 'SliderStep', sliderStep);
set(handles.sliderAngle, 'Value', sliderMin);

%set(handles.axesBeamProfile,'XLimMode','manual');
%set(handles.axesBeamProfile,'YLimMode','manual');
set(handles.axesBeamProfile, 'Visible', 'off', 'CLim', [0 1]);

SetBeamProfile(handles, sliderMin);
SetLine(hObject , handles, sliderMin)

guidata(hObject, handles);
% UIWAIT makes BeamProfile wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = BeamProfile_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function sliderAngle_Callback(hObject, eventdata, handles)
% hObject    handle to sliderAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currentSliderStep = round(get(hObject, 'Value'));
angle = handles.XData(currentSliderStep);
set(handles.txtAngle, 'String', sprintf('%.1f°', angle));

SetBeamProfile (handles, currentSliderStep);
SetLine(hObject, handles, currentSliderStep);

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% --- Executes during object creation, after setting all properties.
function sliderAngle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function SetBeamProfile (handles ,column)

profile = handles.image(:,(round (column)));
profile = profile/handles.max;
area (handles.axesBeamProfile, handles.YData, profile);
hLy = get(handles.axesTransformed, 'YLabel');
s = get(hLy, 'String');
xlabel(handles.axesBeamProfile, s);
ylabel(handles.axesBeamProfile, 'I / I_{max}');



function SetLine(hObject , handles, column)

hold(handles.axesTransformed, 'on');
Tchild = get(handles.axesTransformed, 'Children');
B = findobj(Tchild,'Type','line');

lineX = handles.XData(round(column));
YMin = 2*handles.YMin; 
YMax = 2*handles.YMax;
if isempty(B) == 1 
    line([lineX lineX], [YMin YMax], 'Parent', handles.axesTransformed);
end
set(B, 'XData', [lineX lineX], 'YData',[YMin YMax]);
guidata(hObject, handles);


% --------------------------------------------------------------------
function MPntClose_Callback(hObject, eventdata, handles)
close(gcf);
