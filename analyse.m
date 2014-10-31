%--------------------------------------------------------------------------
%
%                   - Anwendung CT-Simulator - Auswertung -
%
%   
%  Folgende Funktionen sind bisher implementiert:
%
%    - Anzeige der übertragenen Bilder
%
%    - Bildeigenschaften anzeigen
%        + Median
%        + Mittelwert
%        + Entropie
%        + Streuung
%
%    - Vergleichseigenschaften
%        + Kreuzkorrelation
%        + Kovarianz
%
%    - Methoden zum Bildvergleich
%        + Frequenzspektrum
%        + Differenzbild
%        + Differenzhistogramm
%        + Streudiagramm
%
%--------------------------------------------------------------------------
function varargout = analyse(varargin)
% ANALYSE MATLAB code for analyse.fig
%      ANALYSE, by itself, creates a new ANALYSE or raises the existing
%      singleton*.
%
%      H = ANALYSE returns the handle to a new ANALYSE or the handle to
%      the existing singleton*.
%
%      ANALYSE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANALYSE.M with the given input arguments.
%
%      ANALYSE('Property','Value',...) creates a new ANALYSE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before analyse_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to analyse_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above txtleftmean to modify the response to help analyse

% Last Modified by GUIDE v2.5 28-Apr-2013 22:33:57

% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @analyse_OpeningFcn, ...
                   'gui_OutputFcn',  @analyse_OutputFcn, ...
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
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Ereignisse (aufgerufen bei Interaktion mit Steuerlementen)
%--------------------------------------------------------------------------


% Bei Aufruf des Figures
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

function analyse_OpeningFcn(hObject, eventdata, handles, varargin)
% Die Funktion wird beim Öffnen der Anwendung analyse aufgerufen.
% hObject    Handle auf die Figure
% eventdata  reserviert - bisher nicht verwendet
% handles    Struktur mit Handles und Benutzerdaten (vgl. GUIDATA)
% varargin   Kommandozeilenargumente, die an CTSim übergeben werden (vgl. VARARGIN)

% Prüfen ob das Figure neu angelegt wurde oder bereits existiert
if (isfield(handles,'data')== 0)
elseif (strcmp(handles.data{1}.info{2} , (get(varargin{1}.hImageUnprocessed,'DisplayName'))) == 0)
    handles = rmfield(handles, 'data');
end

%Datensatz Originalbild anlegen
handles.data{1}.image.CData = get(varargin{1}.hImageUnprocessed, 'CData');
handles.data{1}.info{2} =  get(varargin{1}.hImageUnprocessed,'DisplayName');
handles.data{1}.info{1} =  'Originalbild';
handles.data{1}.name = strcat(handles.data{1}.info{2},'-', handles.data{1}.info{1});

%Index Bilderanzahl
currentIndex = length(handles.data);

%Datensatz Transformationsbild anlegen
handles.data{currentIndex+1}.image.CData = get(varargin{1}.hImageReconstructed, 'CData');
handles.data{currentIndex+1}.info{5} = varargin{3}.interpolation;
handles.data{currentIndex+1}.info{4} = varargin{3}.filter;
handles.data{currentIndex+1}.info{3} = strcat('Transformationstyp: ',32,GetTransformType((varargin{2}.transformType)));
handles.data{currentIndex+1}.info{2} = strcat('Winkelauflösung: ',32,num2str(varargin{2}.angleResolution),'°');
handles.data{currentIndex+1}.info{1} = 'Rücktransformation';
handles.data{currentIndex+1}.name = strcat(num2str(currentIndex),'. ',handles.data{currentIndex+1}.info{1},' (', handles.data{currentIndex+1}.info{4},', ', handles.data{currentIndex+1}.info{5},')');

%Wird bei neuem Originalbild ausgeführt
%Setzt Auswertung auf Anfangszustand
if (currentIndex == 1)
    handles.hImage{1} = handles.data{1}.image;
    handles.hImage{2} = handles.data{1}.image;
    axes(handles.imageboxleft);        
    imshow(handles.hImage{1}.CData);
    set(handles.imageboxleft, 'Visible', 'off');
    axes(handles.imageboxright);        
    imshow(handles.hImage{2}.CData);
    set(handles.imageboxright, 'Visible', 'off');
    CalculateAndSetImagePropertys(handles, hObject, 2);
    CalculateAndSetImagePropertys(handles, hObject, 1);
    CalculateAndSetComparison(handles, hObject);
end

%Aktualisieren der Listbox
guidata(hObject, handles);
SetListbox(hObject, handles);
%---------------------------------------------------------------------

%=====================================================================
function CalculateAndSetImagePropertys (handles, himage, index)
%Berechnung und Anzeige von Eigenschaften der Einzelbilder
%Ablage des Bild handles
pic = handles.hImage{index}.CData;

%Berechnung von Mittelwert, Standardabweichung, Entropie, Median
mean = mean2(pic)*255;
stad = std2(pic);
ent = entropy(pic);
med = median(pic(:)*255);

%Unterscheidung des index zur Anzeige der Bildeigenschaften
if (index == 1)
%Linke Bildeigenschaften werden aktualisiert
    set(handles.txtleftmean,'String', num2str(mean));
    set(handles.txtleftstr,'String', num2str(stad));
    set(handles.txtleftent,'String', num2str(ent));
    set(handles.txtleftmed,'String', num2str(med));
end
if (index == 2)
%Rechte Bildeigenschaften werden aktualisiert
    set(handles.txtrightmean,'String', num2str(mean));
    set(handles.txtrightstr,'String', num2str(stad));
    set(handles.txtrightent,'String', num2str(ent));
    set(handles.txtrightmed,'String', num2str(med));
end
%---------------------------------------------------------------------

%=====================================================================
function CalculateAndSetComparison(handles, hObject)
%Kalkulation und Setzen der Vergleichsparameter

%Ablegen der Bilddaten-Referenz in lokalen Variablen
im1 = handles.hImage{1}.CData;
im2 = handles.hImage{2}.CData;

%Größe anpassen für den Fehlerfall das Bilder ungleiche Größe haben
im1 = imresize(im1,[512 512], 'bicubic');
im2 = imresize(im2,[512 512], 'bicubic');

%Korrealtion berechnen unter Berücksichtigung des Bildzentrums
for i=1:1:5
for j=1:1:5
%Verschieben der Bilder übereinander
correlation(i,j) = corr2 (im1(3:1:end-2,3:1:end-2), im2(i:1:end-5+i,j:1:end-5+j));
end
end

%Maximalwert der Korrelation bestimmen und dazugehöriger Position festlegen
[maxval idx] = max(correlation(:));
[x y] = ind2sub(size(correlation),idx);

%Berechnung der Kovarianz
covariants = cov (im1(3:1:end-2,3:1:end-2), im2(x:1:end-5+x,y:1:end-5+y));

%Anzeige der Werte
set(handles.txtcorr, 'String', num2str(maxval));
set(handles.txtcovar, 'String', num2str(covariants(1,2)));
guidata(hObject, handles);

% --------------------------------------------------------------------

%=====================================================================
function lstboxleft_Callback(hObject, eventdata, handles)
%Ereignis bei Änderung der linken Textbox

%Ausgeähltes Element in handle ablegen
index_selected = get(hObject, 'Value');
handles.hImage{1} = handles.data{index_selected}.image;

%Neue Werte für Bildeigenschaften und Bildvergleich berechnen
CalculateAndSetImagePropertys(handles, hObject, 1);
CalculateAndSetComparison(handles, hObject);

%Löscht/Schreibt Textanzeige unter linker Textbox
set(handles.txtboxleft1, 'String', '');
set(handles.txtboxleft2, 'String', '');
if (index_selected > 1)
set(handles.txtboxleft1, 'String', handles.data{index_selected}.info{2});
set(handles.txtboxleft2, 'String', handles.data{index_selected}.info{3});
end

%Zeigt ausgewähltes Bild in linker Anzeigebox
axes(handles.imageboxleft);        
imshow(handles.hImage{1}.CData);
set(handles.imageboxleft, 'Visible', 'off');
guidata(hObject, handles);
%---------------------------------------------------------------------

%=====================================================================
function lstboxright_Callback(hObject, eventdata, handles)
% Ereignis bei Änderung der rechten Textbox

%Ausgewähltes Element in handle ablegen
index_selected = get(hObject, 'Value');
handles.hImage{2} = handles.data{index_selected}.image;
handles.hImage{2}.info = get(hObject, 'String');

%Neue Werte für Bildeigenschaften und Bildvergleich berechnen
CalculateAndSetImagePropertys(handles, hObject, 2);
CalculateAndSetComparison(handles, hObject);

%Löscht/Schreibt Textanzeige unter rechter Textbox
set(handles.txtboxright1, 'String', '');
set(handles.txtboxright2, 'String', '');
if (index_selected > 1)
set(handles.txtboxright1, 'String', handles.data{index_selected}.info{2});
set(handles.txtboxright2, 'String', handles.data{index_selected}.info{3});
end

%Zeigt ausgewähltes Bild in rechter Anzeigebox
axes(handles.imageboxright);        
imshow(handles.hImage{2}.CData);
set(handles.imageboxright, 'Visible', 'off');
guidata(hObject, handles);
%---------------------------------------------------------------------

%=====================================================================
% --- Executes on button press in btndiffimage.
function btndiffimage_Callback(hObject, eventdata, handles)
% hObject    handle to btndiffimage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Anpassen der Bildschirmgröße bei unterschiedlichen Elementen
im1 = imresize(handles.hImage{1}.CData,[512 512], 'bicubic');
im2 = imresize(handles.hImage{2}.CData,[512 512], 'bicubic');

%Erzeugt ein Differenzbild aus den beiden vorhandenen Bilder
diffim = im1 - im2;

%Erstellt ein neues Figure in dem das Differnzbild angezeigt wird
hFigure = figure('name','Differenzbild');
hAxes = subplot(1, 1, 1, 'Parent', hFigure);
imshow(abs(diffim));
% --------------------------------------------------------------------

%=====================================================================
function btnhistogram_Callback(hObject, eventdata, handles)
% --- Executes on button press in btnhistogram.
% hObject    handle to btnhistogram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Anpassen der Bildergröße im Fehlerfall (unterschiedliche Größe)
im1 = imresize(handles.hImage{1}.CData,[512 512], 'bicubic');
im2 = imresize(handles.hImage{2}.CData,[512 512], 'bicubic');

%Erzeugt ein neues Figure mit bestimmter Größe
hFigure = figure('name','Histogramme','Position',[0, 0, 840, 600]);

%Zeigt das Histogramm des linken Bildes
hAxes = subplot(3, 1, 1, 'Parent', hFigure);
imhist(im1);

%Holt die Bezeichnung für das linke Bild und schreibt diesen über das subplot
selected_item=get(handles.lstboxleft,'value');
selected_string = get(handles.lstboxleft,'String');
title(selected_string{selected_item});

%Zeigt das Histogramm des zweiten Bildes
hAxes = subplot(3, 1, 2, 'Parent', hFigure);
imhist(im2);

%Holt die Bezeichnung für das rechte Bild und schreibt diesen über das subplot
selected_item=get(handles.lstboxright,'value');
selected_string = get(handles.lstboxright,'String');
title(selected_string{selected_item});

%Bildet die Differenz der beiden Histogramme
hAxes = subplot(3, 1, 3, 'Parent', hFigure);
imhist(abs(im1-im2));

%erzeugt die Beschriftung über das Differenzhistogramm und zeigt dieses an
title('Differenzhistogramm');
selected_item=get(handles.lstboxleft,'value');
selected_string = get(handles.lstboxleft,'String');
selected_string{selected_item};

% --------------------------------------------------------------------

%=====================================================================
% --- Executes on button press in btnstreudiagramm.
function btnstreudiagramm_Callback(hObject, eventdata, handles)
% hObject    handle to btnstreudiagramm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
im1 = imresize(handles.hImage{1}.CData,[256 256], 'bicubic');
im2 = imresize(handles.hImage{2}.CData,[256 256], 'bicubic');

%Erzeugt ein neues Figure zur Anzeige des Streudiagramms
hFigure = figure('name','Streudiagramm','Position',[0, 0, 840, 600]);
%Zeigt das Streudiagramm an
scatter(im1(:),im2(:));

%Beschriftung für x Koordinaten werden geholt und angezeigt
selected_item=get(handles.lstboxleft,'value');
selected_string = get(handles.lstboxleft,'String');
xlabel(selected_string{selected_item});

%Beschriftung für y Koordinaten werden geholt und angezeigt
selected_item=get(handles.lstboxright,'value');
selected_string = get(handles.lstboxright,'String');
ylabel(selected_string{selected_item});

% --------------------------------------------------------------------

%=====================================================================
function btnfrequ_Callback(hObject, eventdata, handles)
% Funktion zur Darstellung des Frequenzspektrum
% --- Executes on button press in btnfrequ.
% hObject    handle to btnfrequ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Ablegen der Bildzeiger und Bildgröße überprüfen
im1 = imresize(handles.hImage{1}.CData,[256 256], 'bicubic');
im2 = imresize(handles.hImage{2}.CData,[256 256], 'bicubic');

% Berechnung der zentrierten Fouriertransformation beider Bilder
im1   = fftshift(im1);
im2   = fftshift(im2);
F1     = fft2(im1);
F2     = fft2(im2);

% Erzeugen eines neuen Figures
hFigure = figure('name','Fourier-Transformation','Position',[0, 0, 840, 600]);

% Bezeichnung aus linken Listbox lesen
selected_item=get(handles.lstboxleft,'value');
selected_string = get(handles.lstboxleft,'String');
% Anzeigefenster wählen und Fourier-Transformierte anzeigen (Betrag)
subplot(2,2,1);
imagesc(100*log(1+abs(fftshift(F1)))); colormap(gray);
title(strcat('Frequenzspektrum -',32, selected_string{selected_item}));
% Phasengang anzeigen und Bezeichnung eintragen
subplot(2,2,3);
imagesc(angle(F1));  colormap(gray);
title(strcat('Phasenspektrum -',32, selected_string{selected_item}));
% Bezeichnung aus rechten Listbox lesen
selected_item=get(handles.lstboxright,'value');
selected_string = get(handles.lstboxright,'String');
% Frequenzspektrum des linken Bildes anzeigen und Bezeichnung eintragen
subplot(2,2,2);
imagesc(100*log(1+abs(fftshift(F2)))); colormap(gray); 
title(strcat('Frequenzspektrum -',32, selected_string{selected_item}));
% Phasenspektrum des linken Bilder anzeigen und Bezeichnung eintragen
subplot(2,2,4);
imagesc(angle(F2));  colormap(gray);
title(strcat('Phasenspektrum -',32, selected_string{selected_item}));
% --------------------------------------------------------------------
%
%---------------------------------------------------------------------
%  Unterfunktionen zur Anzeige der Zeichenkette
%---------------------------------------------------------------------
%
%=====================================================================
function [string] =  GetTransformType(index)
%Hilfsfunktion zur Rückgabe des entsprechenden Transformationstyps
if (index==1)
    string = 'Parallelstrahl (Radon-Transformation)';
end
if (index==2)
    string = 'Fächerstrahl (Kreisförmig)';
end
if (index==3)
    string = 'Fächerstrahl (Linienförmig)';
end
%Rückgabe der Zeichenkette
% --------------------------------------------------------------------

%=====================================================================
function SetListbox (hObject, handles)
%Aktualisieren der LIstboxen
for i=1:1:length(handles.data)
    lststring{i} = handles.data{i}.name;
end
set(handles.lstboxleft, 'String', lststring);
set(handles.lstboxright, 'String', lststring);
guidata(hObject, handles);
% --------------------------------------------------------------------
%
%---------------------------------------------------------------------
% Funktionen für Auto - GUI
%---------------------------------------------------------------------
%
%=====================================================================
function MPntFile_Callback(~,~,~)
% --------------------------------------------------------------------

%=====================================================================
function MPntClose_Callback(hObject, eventdata, handles)
close(gcf);
% --------------------------------------------------------------------

%=====================================================================
function lstboxleft_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstboxleft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes on selection change in lstboxright.
%---------------------------------------------------------------------

%=====================================================================
% --- Executes during object creation, after setting all properties.
function lstboxright_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstboxright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%---------------------------------------------------------------------

%=====================================================================
function varargout = analyse_OutputFcn(hObject, eventdata, handles) 
% Callback
% --- Outputs from this function are returned to the command line.
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;

% --- Executes on selection change in lstboxleft.
% --- Executes on selection change in lstboxleft.
%---------------------------------------------------------------------
