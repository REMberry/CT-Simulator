%--------------------------------------------------------------------------
%
%                   - Anwendung CT-Simulator -
%
%   
%  Folgende Funktionen sind bisher implementiert:
%
%    - vorgefertigte Bildprimitive oder Bild aus einer Datei laden
%
%    - Vorverarbeitung
%        + Kontrast anpassen
%        + Rauschen hinzuf�gen
%        + Bild invertieren
%        + Vorverarbeitungsschritte r�ckg�ngig machen
%
%    - Transformation eines Bildes
%        + Parallel- und F�cherstrahl
%        + einstellbare Aufl�sung des Drehwinkels, Abstand Stragl/Sensor
%          und Abstand der Sensoren untereinander
%
%    - R�cktransformation
%        + mit verschiedenen Interpolations- und Filtermethoden
%
%    - Bildauswertung
%
% � Manuel Wirsch & Michael K�gel
%--------------------------------------------------------------------------


%=====================================================================
function varargout = CTSim(varargin)
% CTSIM M-file for CTSim.fig
%      CTSIM, by itself, creates a new CTSIM or raises the existing
%      singleton*.
%
%      H = CTSIM returns the handle to a new CTSIM or the handle to
%      the existing singleton*.
%
%      CTSIM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CTSIM.M with the given input arguments.
%
%      CTSIM('Property','Value',...) creates a new CTSIM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CTSim_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CTSim_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CTSim

% Last Modified by GUIDE v2.5 29-Apr-2013 12:16:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CTSim_OpeningFcn, ...
                   'gui_OutputFcn',  @CTSim_OutputFcn, ...
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
%---------------------------------------------------------------------


%--------------------------------------------------------------------------
% private Funktionen
%--------------------------------------------------------------------------


% Allgemein
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


%=====================================================================
function [cb, ce] = GetEmptyRowCount(M)
% Anzahl aller leeren Zeilen, ab Beginn (cb) und vom Ende an (ce)
% bis Daten enthalten sind

% Zeilenanzahl
[r, ~] = size(M);

% Anzahl leerer Zeilen zu Beginn
cb = 0;
for i = 1 : r
    if any(M(i,:))
        break;
    else
        cb = cb + 1;
    end
end

% Anzahl leerer Zeilen vom Ende an
ce = 0;
for i = r : - 1 : 1
    if any(M(i,:))
        break;
    else
        ce = ce + 1;
    end
end
%---------------------------------------------------------------------


%=====================================================================
function EnableControls(Parent, Enable)
% alle Steuerlemente eines Parent aktivieren/deaktivieren

% Steuerelemente ermitteln, die eine Enable-Eigenschaft haben
ctrls = findobj(Parent, '-property', 'Enable');
for i = 1 : numel(ctrls)
    set(ctrls(i), 'Enable', Enable);
end
%---------------------------------------------------------------------


%=====================================================================
function SetStatusbarText(statusText)
% Text in der Statusbar setzen

handles = guidata(gcbo);
set(handles.TxtStatusText, 'String', statusText);
guidata(gcbo, handles);

% sofort anzeigen
drawnow;
%---------------------------------------------------------------------


%=====================================================================
function SetBusyState()
% Anzeigen, dass die Anwendung mit einer Verarbeitung besch�ftigt ist

SetStatusbarText('Busy ...');
%---------------------------------------------------------------------


%=====================================================================
function ClearBusyState()
% Anzeigen, dass Verarbeitung abgeschlossen ist

SetStatusbarText('');
%---------------------------------------------------------------------



% Verarbeitung / Programmzust�nde setzen
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


%=====================================================================
function [result] = GetProcessState(handles)
% aktuellen Verarbeitungsschritt ermitteln
%   0 - kein Bild geladen
%   1 - Bild geladen
%   2 - Bild transformiert
%   3 - Bild r�cktransformiert

imgLoaded = ~isempty(handles.images.hImageUnprocessed);
imgTransformed = ~isempty(handles.images.hImageTransformed);
imgReconstructed = ~isempty(handles.images.hImageReconstructed);

% Bild r�cktransformiert
if imgReconstructed
    state = 3;
% Schritte bis zum Sinogramm ausgef�hrt
elseif imgTransformed 
    state = 2;
% Bisher nur ein Bild geladen und vorverarbeitet
elseif imgLoaded
    state = 1;
else
% bisher kein Bild geladen
    state = 0;
end
result = state;
%---------------------------------------------------------------------


%=====================================================================
function CTSim_UpdateMenuItemsState(hObject, handles)
% G�ltigen Zustand der einzelnen Menueintr�ge herstellen, so
% dass Items inaktiv sind, die nicht verwnedte werden d�rfen

% aktuellen Verarbeitunggschritt auslesen
state = GetProcessState(handles);
% m�gliche Items, wenn ein Bild geladen wurden
% Kontrastanpassung
set(handles.MPntAdjustContrast, 'Enable', Bool2Enable((state > 0)));
% MATLAB-Tool PixelRegion
set(handles.MPntPixelRegion, 'Enable', Bool2Enable((state > 0)));
% Graustufen invertieren
set(handles.MPntInvertImage, 'Enable', Bool2Enable((state > 0)));
% R�ckg�ngig m�glich, wenn Daten in undoUnprocessedImages
undoPossible = ~isempty(handles.undoUnprocessedImages);
set(handles.MPntUndo, 'Enable', Bool2Enable(undoPossible));
guidata(hObject, handles);
%---------------------------------------------------------------------


%=====================================================================
function CTSim_UpdateGUIControls(hObject, handles)
% Alle Steuerelemente auf einen g�ltigen Zustand setzen ,so dass diese nur
% aktiv sind, wenn auch benutzbar (z. B. Transformation nur aktivieren,
% wenn ein Bild geladen wurde)

% aktuellen Verarbeitunggschritt auslesen
state = GetProcessState(handles);
TextHandles = [...
    handles.txtStepLoadPicture,...
    handles.txtStepPreProcess,...
    handles.txtStepTransform,...
    handles.txtStepInvTransform];

% aktuellen Verarbeitungsschritt in blauer Schrift unterhalb des Menus 
% anzeigen
for i = 1 : numel(TextHandles)
    TextHandle = TextHandles(i);
    v = get(TextHandle, 'Value');
    if (v < state)
        set(TextHandle, 'ForegroundColor', 'black');
    elseif (v == state)
        set(TextHandle, 'ForegroundColor', 'blue');
    else
        set(TextHandle, 'ForegroundColor', [0.5 0.5 0.5]);
    end
end

% Steuerelemente abh�ngig vom Verarbeitungsschritt aktivieren/deaktivieren
switch state
    % kein Bild geladen
    case 0
            EnableControls(handles.PnlPreProcessImage, 'off');
            EnableControls(handles.PnlTransformation, 'off'); 
            EnableControls(handles.PnlInvTransformation, 'off');
            EnableControls(handles.PnlProcessAnalysis, 'off');
    % Bild geladen, bisher nicht transformiert
    case 1
            EnableControls(handles.PnlPreProcessImage, 'on');
            EnableControls(handles.PnlTransformation, 'on'); 
            EnableControls(handles.PnlInvTransformation, 'off');
            EnableControls(handles.PnlProcessAnalysis, 'off');  
    % Bild geladen und transformiert/r�cktransformiert
    otherwise
            EnableControls(handles.PnlPreProcessImage, 'on');
            EnableControls(handles.PnlTransformation, 'on'); 
            EnableControls(handles.PnlInvTransformation, 'on');
            % Analyse aktivieren, wenn Bild r�cktransformiert
            if (state > 2)
                EnableControls(handles.PnlProcessAnalysis, 'on');
            else
                EnableControls(handles.PnlProcessAnalysis, 'off');
            end;
end

% Steuerelemente abh�ngig von anderen Steuerelementen setzen
if state > 0
    % Projektionsart
    % bei Parallel-Beam (Radon) ist der Abstand Strahl/Sensor und Abstand der
    % Sensoren untereinander nicht einstellbar
    selObj = get(handles.PnlProjection, 'SelectedObject');
    transformType = get(selObj, 'UserData');
    if (transformType == 1)
        EnableControls(handles.PnlDistanceFactor, 'off');
        EnableControls(handles.PnlSpaceSensors, 'off');
    else
        EnableControls(handles.PnlDistanceFactor, 'on');
        EnableControls(handles.PnlSpaceSensors, 'on');
    end
    % wenn mit F�cher-Beam transformiert, dann ist die ungefilterte
    % R�ckprojektion und die Cubic-V5-Interpolation nicht m�glich
    if state > 1
        if (handles.transform.transformType == 1)
            set(handles.RBtnInvTransfIntpCubicV5, 'Enable', 'on');
            set(handles.RBtnInvTransFltNone, 'Enable', 'on');
        else
            set(handles.RBtnInvTransfIntpCubicV5, 'Enable', 'off');
            if get(handles.RBtnInvTransfIntpCubicV5, 'Value') > 0
                set(handles.RBtnInvTransfIntpLinear, 'Value', 1.0);
            end
            set(handles.RBtnInvTransFltNone, 'Enable', 'off');
            if get(handles.RBtnInvTransFltNone, 'Value') > 0
                set(handles.RBtnInvTransFltSheppLogan, 'Value', 1.0);
            end
        end
    end
end
% vorverarbeitete Inhalte vorhanden, sonst Steuerelemente deaktivieren,
% die Vorverarbeitung r�ckg�ngig machen sollen
undoPossible = ~isempty(handles.undoUnprocessedImages);
set(handles.BtnUndo, 'Enable', Bool2Enable(undoPossible));

% Menueintr�ge an den aktuellen Zustand der Verarbeitung anpassen
CTSim_UpdateMenuItemsState(hObject, handles)
guidata(hObject, handles);
%---------------------------------------------------------------------


%=====================================================================
function CTSim_UpdateNewImageState(...
    hObject, handles, newImageData, newImageState, displayName)
% Diese Funktion wird aufgerufen, sobald  ein neues Bild geladen wurde
%   Parameter
%     hObject - Handle auf Figure
%     handles - Handles-Struktur
%     newImageData - Matrix mit neuen Bilddaten
%     newImageState - Zustand des Bildes
%       new: Bild aus Datei geladen / Bildprimitiv geladen
%       undo: letzte Vorverarbeitung r�ckg�ngig machen
%       preprocess: Bild wurde einer Vorverarbeitung unterzogen
%     displayName- angezeigter Name in der Bildauswertung

if (nargin < 5) 
    displayName = get(handles.images.hImageUnprocessed, 'DisplayName');
end

% wenn neues Bild, dann Matrix mit Undo-Bilddaten leeren
if (strcmp(newImageState, 'new')) 
    handles.undoUnprocessedImages = {};
% Undo: vorherigen Bildinhalt setzen
elseif (strcmp(newImageState, 'undo')) && ~isempty((handles.undoUnprocessedImages))
    handles.CTImageUnprocessed = handles.undoUnprocessedImages{end};
    if length(handles.undoUnprocessedImages) > 1
        handles.undoUnprocessedImages = ...
            handles.undoUnprocessedImages(1, 1:end-1);
    else
        handles.undoUnprocessedImages = {};
    end
% Vorverarbeitung: aktuelles Bild in die Undo-Bildinhalte packen (max. 10)
elseif (strcmp(newImageState, 'preprocess'))
    % 10x R�ckg�ngig sollte mehr als genug sein
    if length(handles.undoUnprocessedImages) > 10
        handles.undoUnprocessedImages = ...
            handles.undoUnprocessedImages(1, 2:end);
    end
    handles.undoUnprocessedImages{end+1} = handles.CTImageUnprocessed;        
end

% neuen Bilddaten setzen, wenn nicht der vorherige Bildinhalt angezeigt
% werden soll
if (~strcmp(newImageState, 'undo'))
    handles.CTImageUnprocessed = newImageData;
end

% ben�tigte Handles 
hAxes = handles.axesImageUnprocessed;
hCtxMenu = handles.CtxUnprocessedPicture;
hImage = imshow(handles.CTImageUnprocessed, 'Parent', hAxes);
handles.images.hImageUnprocessed = hImage;

% Werte setzen (DisplayName)
set(hImage, 'hittest','on', 'UIContextMenu', hCtxMenu, 'DisplayName', displayName);
% Intesit�t des Bildes zw. 0...1
set(hAxes, 'Visible', 'off', 'CLim', [0 1]);

% Achse f�r transformiertes und r�cktransformiertes Bild verbergen
hAxes = handles.axesImageTransformed;
cla(hAxes, 'reset');
set(hAxes, 'Visible', 'off');
handles.images.hImageTransformed = [];

hAxes = handles.axesImageReconstructed;
cla(hAxes, 'reset');
set(hAxes, 'Visible', 'off');
handles.images.hImageReconstructed = [];

guidata(hObject, handles);
% alle Steuerlemente auf einen g�ltigen Zustand setzen (abh�ngig vom
% aktuellen Verarbeitungsschritt)
CTSim_UpdateGUIControls(hObject, handles);
%---------------------------------------------------------------------


%=====================================================================
function CTSim_CTImageTransformProcessed(hObject, handles)
% Das transformiertes Bild (Sinogramm) anzeigen

hAxes = handles.axesImageTransformed;
hCtxMenu = handles.CtxTransformedPicture;
transformType = handles.transform.transformType;

% Daten abh�ngig vom Transformationstyp setzen/holen
switch transformType
    % Parallel-Beam
    case 1
        T = handles.transform.pbeam.T;
        y = handles.transform.pbeam.xProj;
        x = handles.transform.pbeam.theta;
        yCaption = 'Sensorposition x''';

    % F�cher-Beam (kreisf�rmig)
    case 2
        T = handles.transform.fbeam.T;
        y = handles.transform.fbeam.angleProj; 
        x = handles.transform.fbeam.theta; 
        yCaption = 'Sensorposition in Grad';
        
    % F�cher-Beam (linienf�rmig)
    case 3
        T = handles.transform.fbeam.T;
        y = handles.transform.fbeam.xProj; 
        x = handles.transform.fbeam.theta; 
        yCaption = 'Sensorposition x''';
end

% Anzahl Leerzeichen zu Beginn und Ende der Matrix auslesen
[cb, ce] = GetEmptyRowCount(T);
ib = 1 + cb;
ie = size(y) - ce; 

% Sinogramm anzeigen (Zeilen ohne Inhalt ausblenden)
T = T / max(T(:));
hImage = imagesc(x, y(ib:ie), T(ib:ie,:), 'Parent', hAxes);
xlabel(hAxes, 'Drehwinkel in Grad');
ylabel(hAxes, yCaption);
% Kontext-Menu um Bild in neuem Fenster darstellen zu k�nnen
set(hImage, 'hittest','on', 'UIContextMenu', hCtxMenu);
% Image-Handle in Struktur ablegen
handles.images.hImageTransformed = hImage;
hAxes = handles.axesImageReconstructed;
cla(hAxes, 'reset');
% Achsen ausblenden, Intensit�tswerte im Bereich 0...1
set(hAxes, 'Visible', 'off', 'CLim', [0 1]);
guidata(hObject, handles);
% alle Steuerlemente auf einen g�ltigen Zustand setzen
CTSim_UpdateGUIControls(hObject, handles);
%---------------------------------------------------------------------


%=====================================================================
function CTSim_CTImageInvTransformProcessed(hObject, handles)
% Das r�cktransformiertes Bild (Sinogramm) anzeigen
hAxes = handles.axesImageReconstructed;
hImage = imagesc(handles.invtransform.image, 'Parent', hAxes);
% keine Achsen anzeigen, Intesit�t im Bereich 0...1
set(hAxes, 'Visible', 'off', 'CLim', [0 1]);
hCtxMenu = handles.CtxProcessedPicture;
% Kontext-Menu um Bild in neuem Fenster darstellen zu k�nnen
set(hImage, 'hittest','on', 'UIContextMenu', hCtxMenu);
% Image-Handle in Struktur ablegen
handles.images.hImageReconstructed = hImage;
guidata(hObject, handles);
% alle Steuerlemente auf einen g�ltigen Zustand setzen
CTSim_UpdateGUIControls(hObject, handles);
%---------------------------------------------------------------------


%=====================================================================
function PnlProjection_SelectionChangeFcn(hObject, ~, handles)
% Aufgerufen, sobald die Projektionsart ge�ndert wird

% g�ltigen Zustand bei Einstellungen Transformation und 
% Interpolatio/Filter setzen
CTSim_UpdateGUIControls(hObject, handles);
%---------------------------------------------------------------------



% Hilfsfunktionen f�r das (Context)-Menu
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


%=====================================================================
function ShowPictureInNewFigure(hImage, caption)
imsave(hImage);

XData = get(hImage, 'XDATA');
YData = get(hImage, 'YDATA');
hParent = get(hImage, 'Parent');
hLx = get(hParent, 'XLabel');
hLy = get(hParent, 'YLabel');

hFigure = figure('Name', caption);
hAxes = subplot(1, 1, 1, 'Parent', hFigure);
hImageParent = get(hImage, 'Parent');
axes(hAxes);
colormap(gray);
imagesc(get(hImage, 'CData'), 'XData', XData, 'YData', YData);

set(hAxes, 'CLim', get(hImageParent, 'CLim'));   
xlabel(hAxes, get(hLx, 'String'));
ylabel(hAxes, get(hLy, 'String'));

%---------------------------------------------------------------------


%--------------------------------------------------------------------------
% Ereignisse (aufgerufen bei Interaktion mit Steuerlementen)
%--------------------------------------------------------------------------


% �ffnen/Schlie�en und Figure vergr��ern
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


%=====================================================================
function CTSim_OpeningFcn(hObject, ~, handles, varargin)
% Die Funktion wird beim �ffnen der Anwendung CTSim aufgerufen.
% hObject    Handle auf die Figure
% eventdata  reserviert - bisher nicht verwendet
% handles    Struktur mit Handles und Benutzerdaten (vgl. GUIDATA)
% varargin   Kommandozeilenargumente, die an CTSim �bergeben werden (vgl. VARARGIN)

% Handles-Struktur initialisieren
% Handle auf Figure
handles.output = hObject;
% Daten des Originalbildes
handles.CTImageUnprocessed = [];
% Image-Handle auf Originalbild
handles.images.hImageUnprocessed = [];
% Image-Handle auf Sinogramm
handles.images.hImageTransformed = [];
% Image-Handle auf r�cktransformiertes Bild
handles.images.hImageReconstructed = [];
% Bilddaten vor entsprechenden Vorverarbeitungsschritten
handles.undoUnprocessedImages = {};

% Axen ausblenden
set(handles.axesImageUnprocessed, 'Visible', 'off');
set(handles.axesImageTransformed, 'Visible', 'off');
set(handles.axesImageReconstructed, 'Visible', 'off');

guidata(hObject, handles);

% Steuerelemente auf g�ltigen Zustand setzen (deaktivieren, wenn nicht
% benutzbar)
CTSim_UpdateGUIControls(hObject, handles);
%---------------------------------------------------------------------


%=====================================================================
function varargout = CTSim_OutputFcn(~, ~, handles) 
% Diese Funktion wird beim Beenden der Anwendung aufgerufen.
% R�ckgabewert wird an die Konsole/Aufrufer zur�ckgegeben.
% varargout  cell array - R�ckgabewerte (vgl. VARARGOUT);
% handles    Struktur mit Handles und Benutzerdaten (vgl. GUIDATA)

% R�ckgabewert
varargout{1} = handles.output;
%---------------------------------------------------------------------


%=====================================================================
function MPntClose_Callback(~, ~, ~)
% Figure schlie�en/beenden
close(gcf);
%---------------------------------------------------------------------


%=====================================================================
function MainFigure_ResizeFcn(hObject, eventdata, handles)
% wird aufgerufen, sobald die Figure in der Gr��e ver�ndert wird
%---------------------------------------------------------------------







% Bild aus Datei ausw�hlen oder Primtiv erzeugen
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%=====================================================================
function MPntOpenFromFile_Callback(hObject, ~, handles)
% Datei �ffnen und ein Bild laden (Menueintrag)
SetBusyState();
[filename, user_canceled] = imgetfile();
% Benutzer hat Datei ausgew�hlt
if (user_canceled ~= 1)
    image = imread(filename);
    % mehr als 2 Farbkan�le (RGB-Bild) -> in Graustufen umwandeln
    if ndims(image) > 2
        image = rgb2gray(image);
    end
    % in den Bereich 0...1 bringen, abh�ngig vom Maximalwert
    image = im2double(image);
    if max(image(:)) > 255.0
        image = image / (4095.0);
    elseif max(image(:)) > 1.0
        image = image / 255.0;
    end
end
% Figure mitteilen, dass ein neues Bild geladen wurde
% entsprechende Steuerelemente aktivieren/deaktivieren
CTSim_UpdateNewImageState(hObject, handles, image, 'new', 'Benutzerdefiniert');
ClearBusyState();
%---------------------------------------------------------------------

%=====================================================================
function BtnLoadPictureFromFile_Callback(hObject, eventdata, handles)
% Datei �ffnen und ein Bild laden (Button)

MPntOpenFromFile_Callback(hObject, eventdata, handles);
%---------------------------------------------------------------------

% Shepp-Logan-Phantom laden
% -------------------------
function MPntSheppLogan_Callback(hObject, ~, handles)
SetBusyState();
image = phantom('Modified Shepp-Logan', 512);
CTSim_UpdateNewImageState(hObject, handles, image, 'new', 'Shepp-Logan');
ClearBusyState();


function BtnLoadSheppLogan_Callback(hObject, eventdata, handles)
MPntSheppLogan_Callback(hObject, eventdata, handles);
    
% Kreis+Rechteck laden
% -------------------------
function BtnLoadArcRectangle_Callback(hObject, ~, handles)
SetBusyState();
pic = zeros(512, 512);

% Rechteck
pic(192:320, 192:320) = 1.0;
% Kreis zeichnen
x0 = 192;
y0 = 192;
%Radius (r^2)
r2 = 64^2;
for x = 128 : 256
    x2 = (x - x0)^2;
    for y = 128 : 256
        y2 = (y - y0)^2;
        if (x2 + y2 <= r2)
            if (pic(y, x) == 1)
                pic(y, x) = 0.0;
            else
                pic(y, x) = 1.0;
            end
        end
    end
end  
 
CTSim_UpdateNewImageState(hObject, handles, pic, 'new', 'Kreis+Rechteck');
ClearBusyState();

function MPntArcRectangle_Callback(hObject, eventdata, handles)
BtnLoadArcRectangle_Callback(hObject, eventdata, handles);

% Rechteck laden
% -------------------------
function BtnLoadRectangle_Callback(hObject, ~, handles)
SetBusyState();
pic = zeros(512, 512);
% Rechteck
pic(224:280, 224:280) = 1.0; 

CTSim_UpdateNewImageState(hObject, handles, pic, 'new', 'Rechteck');
ClearBusyState();

function MPntRectangle_Callback(hObject, eventdata, handles)
BtnLoadRectangle_Callback(hObject, eventdata, handles);



% ------------------------ Bild vorverarbeiten ----------------------------


% Originales Farbbild in Graustufen wandeln
function MPntGrayscale_Callback(hObject, ~, handles)


function BtnGrayscale_Callback(hObject, eventdata, handles)
MPntGrayscale_Callback(hObject, eventdata, handles);



% Graustufenanpassung im Originalbild
function MPntAdjustContrast_Callback(hObject, ~, handles)
hFigure = imcontrast(handles.axesImageUnprocessed);
set(hFigure, 'Name', 'Kontrast anpassen');
uiwait(hFigure);
image = getimage(handles.axesImageUnprocessed);
guidata(hObject, handles);
CTSim_UpdateNewImageState(hObject, handles, image, 'preprocess');


function BtnAdjustContrast_Callback(hObject, eventdata, handles)
MPntAdjustContrast_Callback(hObject, eventdata, handles)


% --- Executes on button press in BtnAddNoise.
function BtnAddNoise_Callback(hObject, eventdata, handles)
% Rauschen hinzuf�gen
CTData = handles.CTImageUnprocessed;
[r, c] = size(CTData);
selObj = get(handles.PnlNoiseLevel, 'SelectedObject');
NoiseLevel = get(selObj, 'UserData');
Noise = NoiseLevel*(rand(r, c) - 0.5);
CTData = CTData + Noise;
CTData(CTData < 0) = 0.0;
CTData(CTData > 1.0 ) = 1.0;
CTSim_UpdateNewImageState(hObject, handles, CTData, 'preprocess');


% das Quellbild invertieren
function BtnInvertImage_Callback(hObject, eventdata, handles)
CTData = handles.CTImageUnprocessed;
CTData = 1.0 - CTData;
guidata(hObject, handles);
CTSim_UpdateNewImageState(hObject, handles, CTData, 'preprocess');

function MPntInvertImage_Callback(hObject, eventdata, handles)
BtnInvertImage_Callback(hObject, eventdata, handles);

% --- Executes on button press in BtnUndo.
function BtnUndo_Callback(hObject, eventdata, handles)
CTSim_UpdateNewImageState(hObject, handles, [], 'undo');

function MPntUndo_Callback(hObject, eventdata, handles)
BtnUndo_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------

% --- Bildauswertung
function BtnProcessAnalysis_Callback(hObject, eventdata, handles)
images = handles.images;
% Handle auf die Bilder
%images.hImageUnprocessed
%images.hImageTransformed 
%images.hImageReconstructed 

transform = handles.transform;
% wichtige Daten
%transform.transformType -> Art der Projektion (Parallel, F�cher)
%transform.angleResolution -> Winkelaufl�sung

invtransform = handles.invtransform;
% wichtige Daten
% invtransform.interpolation -> Interpolation
% invtransform.filter -> Filter

% den Namen in der Listbox eventuell aus Art der Projektion, Interpolation
% und Filter zusammensetzen

% der Bildauswertung hinzuf�gen
analyse(images, transform, invtransform);

% --------------------------------------------------------------------



% --------------------------------------------------------------------
% Lupenfunktion und Pixelwerte anzeigen
function MPntPixelRegion_Callback(hObject, eventdata, handles)
uiwait(impixelregion(handles.axesImageUnprocessed));


% --------------------------------------------------------------------
function CtxMPntUnprocessedPicture_Callback(hObject, eventdata, handles)
ShowPictureInNewFigure(handles.images.hImageUnprocessed, 'Originalbild');

% --------------------------------------------------------------------
function CtxMPntTransformedPicture_Callback(hObject, eventdata, handles)
ShowPictureInNewFigure(handles.images.hImageTransformed, 'Sinogramm');

% --------------------------------------------------------------------
function CtxMPntProcessedPicture_Callback(hObject, eventdata, handles)
ShowPictureInNewFigure(handles.images.hImageReconstructed, 'Rekonstruiertes Bild');

% --------------------------------------------------------------------
function CtxUnprocessedPicture_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function CtxTransformedPicture_Callback(hObject, eventdata, handles)

function MPntPreProcess_Callback(hObject, eventdata, handles)



    

% --- Executes on button press in BtnProcessTransform.
function BtnProcessTransform_Callback(hObject, ~, handles)
% Projektionsart
selObj = get(handles.PnlProjection, 'SelectedObject');
transformType = get(selObj, 'UserData');
% Winkelaufl�sung
selObj = get(handles.PnlProjResolution, 'SelectedObject');
angleResolution = get(selObj, 'UserData');
% Abstand Sensor <-> Strahl
selObj = get(handles.PnlDistanceFactor, 'SelectedObject');
minDistanceFactor = get(selObj, 'UserData');
% Abstand der Sensoren untereinander
selObj = get(handles.PnlSpaceSensors, 'SelectedObject');
sensorSpace = get(selObj, 'UserData');

% Daten in Struktur ablegen
handles.transform.transformType = transformType;
handles.transform.angleResolution = angleResolution;

img = handles.CTImageUnprocessed;
imgSize = size(img);
distance = ceil((0.5 * sqrt(imgSize * imgSize'))) + 3.0;
distance = distance * minDistanceFactor;

SetBusyState();

switch transformType
    case 1
        % Radon-Transf. berechnen
        theta = 0:angleResolution:360-angleResolution;
        [T, xProj] = ...
            radon(img, theta);        
        % Daten in Struktur ablegen
        handles.transform.pbeam.T = T;
        handles.transform.pbeam.xProj = xProj;
        handles.transform.pbeam.theta = theta;
    case 2
        % Abstand der Sensoren <-> minimaler Winkelabstand
        sensorSpaceDeg = acos(1-sensorSpace^2/(2*distance^2)) / pi * 180;
        [T, FanPosArcDeg, FanPosAngles] = fanbeam(...
            img, distance,...
            'FanSensorGeometry', 'arc', ...
            'FanRotationIncrement', angleResolution,...
            'FanSensorSpacing', sensorSpaceDeg);
        handles.transform.fbeam.T = T;
        handles.transform.fbeam.angleProj = FanPosArcDeg;
        handles.transform.fbeam.theta = FanPosAngles; 
        handles.transform.fbeam.distance = distance;
        handles.transform.fbeam.sensorSpace = sensorSpaceDeg;
        
    case 3
        [T, xProj, FanPosAngles] = fanbeam(...
            img, distance,...
            'FanSensorGeometry','line',...
            'FanRotationIncrement', angleResolution,...
            'FanSensorSpacing', sensorSpace);
        handles.transform.fbeam.T = T;
        handles.transform.fbeam.xProj = xProj;
        handles.transform.fbeam.theta = FanPosAngles;
        handles.transform.fbeam.distance = distance;
        handles.transform.fbeam.sensorSpace = sensorSpace;
end
guidata(hObject, handles);
CTSim_CTImageTransformProcessed(hObject, handles);
ClearBusyState();


% --- Executes on button press in BtnProcessInvTransformation.
function BtnProcessInvTransformation_Callback(hObject, ~, handles)

transformType = handles.transform.transformType;
% Interpolation
selObj = get(handles.PnlInvTransInterpolation, 'SelectedObject');
interpolationType = get(selObj, 'UserData');
% Filter
selObj = get(handles.PnlInvTransfFilter, 'SelectedObject');
filterType = get(selObj, 'UserData');
SetBusyState();

switch transformType
    case 1
        % Radon-Transf. berechnen
        theta = handles.transform.pbeam.theta;
        T = handles.transform.pbeam.T;

        [I, H] = iradon(T, theta, interpolationType, filterType);        
    otherwise
        % Radon-Transf. berechnen
        T = handles.transform.fbeam.T;
        if transformType == 2
            sensorGeometry = 'arc';
        else
            sensorGeometry = 'line';
        end
        distance = handles.transform.fbeam.distance;
        angleResolution = handles.transform.angleResolution;
        sensorSpace = handles.transform.fbeam.sensorSpace;
        outputSize = max(size(handles.CTImageUnprocessed));

        [I, H] = ifanbeam(T, distance,...
            'FanCoverage', 'cycle',...
            'FanRotationIncrement', angleResolution,...
            'FanSensorGeometry', sensorGeometry,...
            'FanSensorSpacing', sensorSpace,...
            'Interpolation', interpolationType,...
            'Filter', filterType,...
            'OutputSize', outputSize); 
       
end
% Daten in Struktur ablegen
handles.invtransform.interpolation = interpolationType;
handles.invtransform.filter = filterType;
handles.invtransform.intensity = I;

maxSrcIntensity = double(max(handles.CTImageUnprocessed(:)));
maxDstIntensity = max(I(:));

image = I*(maxSrcIntensity/maxDstIntensity);

image(image < 0) = 0;
handles.invtransform.image = image;
handles.invtransform.intensity = I;
handles.invtransform.freqresponse = H;
guidata(hObject, handles);
CTSim_CTImageInvTransformProcessed(hObject, handles);
ClearBusyState();


% --------------------------------------------------------------------
function CtxMPntBeamProfile_Callback(hObject, eventdata, handles)
% 
%
BeamProfile(handles.images.hImageTransformed, handles.transform);
