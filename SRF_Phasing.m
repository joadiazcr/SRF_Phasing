function varargout = SRF_Phasing(varargin)
% SRF_PHASING MATLAB code for SRF_Phasing.fig
%      SRF_PHASING, by itself, creates a new SRF_PHASING or raises the existing
%      singleton*.
%
%      H = SRF_PHASING returns the handle to a new SRF_PHASING or the handle to
%      the existing singleton*.
%
%      SRF_PHASING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SRF_PHASING.M with the given input arguments.
%
%      SRF_PHASING('Property','Value',...) creates a new SRF_PHASING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SRF_Phasing_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SRF_Phasing_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SRF_Phasing

% Last Modified by GUIDE v2.5 21-Feb-2017 09:21:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SRF_Phasing_OpeningFcn, ...
                   'gui_OutputFcn',  @SRF_Phasing_OutputFcn, ...
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

% --- Executes just before SRF_Phasing is made visible.
function SRF_Phasing_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SRF_Phasing (see VARARGIN)

% Default matrix: handles.M (G, E, p1, p2, dp)
% Edit *.fig file to change default M elements (e.g., M(1,1) = Linac-1 gradient)
for ii = 1:4
  for jj = 1:5
    cmd = ['handles.M(' num2str(ii) ',' num2str(jj) ') = str2double(get(handles.TB' num2str(ii) num2str(jj) ',''string''));'];
    eval(cmd)
  end
end

%Control Bits
handles.s_L1_LH = 0;
handles.a_L1_LH = 0;

%Save initial gradient value of all cavities
cav_name = meme_names('name','KLYS:%:PDES','show','dname');
cav_p_des = lcaGetSmart(meme_names('name','KLYS:%:PDES'));
cav_g_des = lcaGetSmart(meme_names('name','KLYS:%:ADES'));%Change to GDES 

[nr,nc]=size(cav_name);
for count = 1:nr
    handles.M_cav{count,1} = cav_name{count,1};
    handles.M_cav{count,2} = cav_p_des(count,1);
    handles.M_cav{count,3} = cav_g_des(count,1);
end
handles.M_cav

handles.cav = cell(1,288); %Preallocation
for i=1:length(cav_name)
    handles.cav{i} = cavity(cav_name(i));
end

%set default setup + CM & cavity to be scanned:
%=============================================
contents = cellstr(get(handles.PM11,'String'));
handles.CM0 = contents{get(handles.PM11,'Value')};
contents = cellstr(get(handles.PM12,'String'));
handles.cav0 = contents{get(handles.PM12,'Value')};
handles.CM_cav0 = [handles.CM0 '-' handles.cav0];
handles.row = 1;    % default to scanning a cavity on the 1st row (Linac-1)
set(handles.SCAN,'String',['Scan: ' handles.CM_cav0])
set(handles.RFONOFF,'String',[handles.CM_cav0 ' RF ON'])
handles.beamon = 1; % enable beam
handles.RF = 1;     % RF on
set(handles.MSG,'String','Ready')
drawnow
handles.Navg = str2double(get(handles.NAVG,'String'));
handles.BPMpvs = {'BPMSE1' 'BPMSX' 'BPMSXp'      % BC1-E + x & x'
                  'BPMSE2' 'BPMSX' 'BPMSXp'      % BC1-E + x & x' (3.9)
                  'BPMSE3' 'BPMSX' 'BPMSXp'      % BC2-E + x & x'
                  'BPMSE4' 'BPMSY' 'BPMSYp'};    % DL-E(Y) + y & y'

% Choose default command line output for SRF_Phasing
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes SRF_Phasing wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = SRF_Phasing_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% Code...
%==========================================================================

% Update panel values
function handles = update(hObject,handles);
handles.CM_cav0 = [handles.CM0 '-' handles.cav0];
set(handles.SCAN,'String',['Scan: ' handles.CM_cav0])
set(handles.RFONOFF,'String',[handles.CM_cav0 ' RF ON'])
set(handles.PM11,'ForegroundColor','black')
set(handles.PM21,'ForegroundColor','black')
set(handles.PM31,'ForegroundColor','black')
set(handles.PM41,'ForegroundColor','black')
set(handles.PM12,'ForegroundColor','black')
set(handles.PM22,'ForegroundColor','black')
set(handles.PM32,'ForegroundColor','black')
set(handles.PM42,'ForegroundColor','black')
cmd = ['set(handles.PM' num2str(handles.row) '1' ',''ForegroundColor'',''blue'')'];
eval(cmd);
cmd = ['set(handles.PM' num2str(handles.row) '2' ',''ForegroundColor'',''blue'')'];
eval(cmd);
% Read bunch charge from machine
% Read bunch rate from machine
% Update charge and rate to "Beam" panel
drawnow
guidata(hObject, handles);


% Linac-1 RF gradient (MV/m):
function TB11_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB11 as text
%        str2double(get(hObject,'String')) returns contents of TB11 as a double
handles.M(1,1) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-1 energy (GeV):
function TB12_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB12 as text
%        str2double(get(hObject,'String')) returns contents of TB12 as a double
handles.M(1,2) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-1 initial RF phase (deg):
function TB13_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB13 as text
%        str2double(get(hObject,'String')) returns contents of TB13 as a double
handles.M(1,3) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-1 final RF phase (deg):
function TB14_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB14 as text
%        str2double(get(hObject,'String')) returns contents of TB14 as a double
handles.M(1,4) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-1 RF phase increment (deg):
function TB15_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB15 as text
%        str2double(get(hObject,'String')) returns contents of TB15 as a double
handles.M(1,5) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% 3.9GHz RF gradient (MV/m):
function TB21_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB21 as text
%        str2double(get(hObject,'String')) returns contents of TB21 as a double
handles.M(2,1) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB21_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% 3.9GHz energy (GeV):
function TB22_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB22 as text
%        str2double(get(hObject,'String')) returns contents of TB22 as a double
handles.M(2,2) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB22_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% 3.9GHz initial RF phase (deg):
function TB23_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB23 as text
%        str2double(get(hObject,'String')) returns contents of TB23 as a double
handles.M(2,3) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB23_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% 3.9GHz final RF phase (deg):
function TB24_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB24 as text
%        str2double(get(hObject,'String')) returns contents of TB24 as a double
handles.M(2,4) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB24_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% 3.9GHz RF phase increment (deg):
function TB25_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB25 as text
%        str2double(get(hObject,'String')) returns contents of TB25 as a double
handles.M(2,5) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB25_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-2 RF gradient (MV/m):
function TB31_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB31 as text
%        str2double(get(hObject,'String')) returns contents of TB31 as a double
handles.M(3,1) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB31_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-2 energy (GeV):
function TB32_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB32 as text
%        str2double(get(hObject,'String')) returns contents of TB32 as a double
handles.M(3,2) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB32_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-2 initial RF phase (deg):
function TB33_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB33 as text
%        str2double(get(hObject,'String')) returns contents of TB33 as a double
handles.M(3,3) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB33_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-2 final RF phase (deg):
function TB34_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB34 as text
%        str2double(get(hObject,'String')) returns contents of TB34 as a double
handles.M(3,4) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB34_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-2 RF phase increment (deg):
function TB35_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB35 as text
%        str2double(get(hObject,'String')) returns contents of TB35 as a double
handles.M(3,5) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB35_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-3 RF gradient (MV/m):
function TB41_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB41 as text
%        str2double(get(hObject,'String')) returns contents of TB41 as a double
handles.M(4,1) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB41_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-3 energy (GeV):
function TB42_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB42 as text
%        str2double(get(hObject,'String')) returns contents of TB42 as a double
handles.M(4,2) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB42_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-3 initial RF phase (deg):
function TB43_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB43 as text
%        str2double(get(hObject,'String')) returns contents of TB43 as a double
handles.M(4,3) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB43_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-3 final RF phase (deg):
function TB44_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB44 as text
%        str2double(get(hObject,'String')) returns contents of TB44 as a double
handles.M(4,4) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB44_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-3 RF phase increment (deg):
function TB45_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of TB45 as text
%        str2double(get(hObject,'String')) returns contents of TB45 as a double
handles.M(4,5) = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function TB45_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% Linac-1 CM pull-down menu:
function PM11_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns PM11 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PM11
contents = cellstr(get(handles.PM11,'String'));
handles.CM0 = contents{get(handles.PM11,'Value')};
contents = cellstr(get(handles.PM12,'String'));
handles.cav0 = contents{get(handles.PM12,'Value')};
handles.row = 1;    % use row-1 of table (Linac-1)
handles = update(hObject,handles);
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function PM11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% 3.9GHz CM pull-down menu:
function PM21_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns PM21 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PM21
contents = cellstr(get(handles.PM21,'String'));
handles.CM0 = contents{get(handles.PM21,'Value')};
contents = cellstr(get(handles.PM22,'String'));
handles.cav0 = contents{get(handles.PM22,'Value')};
handles.row = 2;    % use row-2 of table (3.9GHz)
handles = update(hObject,handles);
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function PM21_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-2 CM pull-down menu:
function PM31_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns PM31 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PM31
contents = cellstr(get(handles.PM31,'String'));
handles.CM0 = contents{get(handles.PM31,'Value')};
contents = cellstr(get(handles.PM32,'String'));
handles.cav0 = contents{get(handles.PM32,'Value')};
handles.row = 3;    % use row-3 of table (Linac-2)
handles = update(hObject,handles);
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function PM31_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-3 CM pull-down menu:
function PM41_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns PM41 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PM41
contents = cellstr(get(handles.PM41,'String'));
handles.CM0 = contents{get(handles.PM41,'Value')};
contents = cellstr(get(handles.PM42,'String'));
handles.cav0 = contents{get(handles.PM42,'Value')};
handles.row = 4;    % use row-4 of table (Linac-3)
handles = update(hObject,handles);
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function PM41_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-1 cavity (1-8) pull-down menu:
function PM12_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns PM12 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PM12
contents = cellstr(get(handles.PM11,'String'));
handles.CM0 = contents{get(handles.PM11,'Value')};
contents = cellstr(get(handles.PM12,'String'));
handles.cav0 = contents{get(handles.PM12,'Value')};
handles.row = 1;    % use row-1 of table (Linac-1)
handles = update(hObject,handles);
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function PM12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% 3.9GHz cavity (1-8) pull-down menu:
function PM22_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns PM22 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PM22
contents = cellstr(get(handles.PM21,'String'));
handles.CM0 = contents{get(handles.PM21,'Value')};
contents = cellstr(get(handles.PM22,'String'));
handles.cav0 = contents{get(handles.PM22,'Value')};
handles.row = 2;    % use row-2 of table (3.9GHz)
handles = update(hObject,handles);
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function PM22_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-2 cavity (1-8) pull-down menu:
function PM32_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns PM32 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PM32
contents = cellstr(get(handles.PM31,'String'));
handles.CM0 = contents{get(handles.PM31,'Value')};
contents = cellstr(get(handles.PM32,'String'));
handles.cav0 = contents{get(handles.PM32,'Value')};
handles.row = 3;    % use row-3 of table (Linac-2)
handles = update(hObject,handles);
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function PM32_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Linac-3 cavity (1-8) pull-down menu:
function PM42_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns PM42 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PM42
contents = cellstr(get(handles.PM41,'String'));
handles.CM0 = contents{get(handles.PM41,'Value')};
contents = cellstr(get(handles.PM42,'String'));
handles.cav0 = contents{get(handles.PM42,'Value')};
handles.row = 4;    % use row-4 of table (Linac-3)
handles = update(hObject,handles);
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function PM42_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Scale all L1-LH magnets and set all of its RF off up to BC1.
function SCL1_Callback(hObject, eventdata, handles)
set(hObject,'Enable','off')
set(handles.ACC1,'Enable','on')
set(handles.SCL2,'Enable','on')
set(handles.ACC2,'Enable','on')
set(handles.SCL3,'Enable','on')
contents = cellstr(get(handles.PM11,'String'));
handles.CM0 = contents{get(handles.PM11,'Value')};
contents = cellstr(get(handles.PM12,'String'));
handles.cav0 = contents{get(handles.PM12,'Value')};
handles.CM_cav0 = [handles.CM0 '-' handles.cav0];
handles.row = 1;    % default to scanning a cavity on 1st row (Linac-1)
set(handles.SCAN,'String',['Scan: ' handles.CM_cav0])
set(handles.RFONOFF,'String',[handles.CM_cav0 ' RF ON'])
handles = update(hObject,handles);
Ec = handles.M(1,2);    % coasting energy (GeV)
% Get all DB names of QUAD, XCOR, YCOR, BEND, BTRM, & SSA in L1-LH (QCM02 thru BCX14)
% Get present E0 and BDES at each magnet (L1-LH)
% Turn off beam at laser
% Turn off all SSA's in L1-LH
% Insert, or check is inserted, the BC1 collimator (block beam)
% Scale down each magnet BDES by ratio of: Ec/E0 (Btrims?)
% TRIM all magnets
% Turn on beam at 1 Hz only (dialog box asks "ready for beam at 1 Hz?")
% Enable phase scan in L1-LH?
%

S = Scale(Ec)
handles.s_L1_LH = 1;

% Magnets & SSA's:
% ===============
% CM02, 1-8 (these 32 RF cavities get turned off)...
% CM03, 1-8
% CMH1, 1-8
% CMH2, 1-8
% QCM02 (these quads get scaled to ~100 MeV)
% QCM03
% Q1C01
% CQ11B
% CQ12B
% XCM02 (these XCORs get scaled to ~100 MeV)...
% XCM03
% XC1C00
% XCM12B
% YCM02  (these YCORs get scaled to ~100 MeV)...
% YCM03
% YC1C00
% YCM12B
% BCX11  (these BC1 BENDs get scaled to ~100 MeV)...
% BCX12
% BCX13
% BCX14
% Btrims (3 BC1 Btrms get scaled also?)
guidata(hObject, handles);


% Set L1-LH RF for acceleration to BC1 and scale all magnets up.
function ACC1_Callback(hObject, eventdata, handles)
set(hObject,'Enable','off')
set(handles.SCL1,'Enable','on')
G  = handles.M(1,1);    % RF gradient (MV/m)
E1 = handles.M(1,2);    % initial energy (GeV)
E2 = handles.M(3,2);    % energy at BC1 (GeV) - after 3.9GHz, so use row=3
p1 = handles.M(1,3);    % starting phase (deg)
p2 = handles.M(1,4);    % ending phase (deg)
dp = handles.M(1,5);    % phase steps (deg)
% Get all DB names of QUAD, XCOR, YCOR, BEND, BTRM, & SSA in L1-LH (QCM02 thru BCX14)
% Get present E0 and BDES at each magnet (L1-LH)
% Turn off beam at laser
% Turn ON all SSA's in L1-LH
% Insert, or check is inserted, the BC1 collimator (block beam)
% Scale each magnet BDES by ratio of: E2/E0 (Btrim?)
% TRIM all magnets
% Turn on beam at 1 Hz only (dialog box asks "ready for beam at 1 Hz?")

handles.a_L1_LH = 1;

guidata(hObject, handles);




% Scale all L2 magnets and set all of its RF off up to BC2.
function SCL2_Callback(hObject, eventdata, handles)
set(hObject,'Enable','off')
contents = cellstr(get(handles.PM31,'String'));
handles.CM0 = contents{get(handles.PM31,'Value')};
contents = cellstr(get(handles.PM32,'String'));
handles.cav0 = contents{get(handles.PM32,'Value')};
handles.CM_cav0 = [handles.CM0 '-' handles.cav0];
handles.row = 3;        % default to scanning a cavity on 3rd row (Linac-2)
set(handles.SCAN,'String',['Scan: ' handles.CM_cav0])
set(handles.RFONOFF,'String',[handles.CM_cav0 ' RF ON'])
handles = update(hObject,handles);
Ec = handles.M(3,2);    % coasting energy to BC2 (GeV)
% Check beam is accelerating in L1/LH up to BC1 (i.e., ACC1 has been run)
% Get all DB names of QUAD, XCOR, YCOR, BEND, BTRM, & SSA in L2 (BCX14+ thru BCX24)
% Get present E0 and BDES at each magnet (L2)
% Turn off beam at laser
% Turn off all SSA's in L2
% Insert, or check is inserted, the BC2 collimator (block beam)
% Scale down each magnet BDES by ratio of: Ec/E0 (Btrims?)
% TRIM all magnets
% Turn on beam at 1 Hz only (dialog box asks "ready for beam at 1 Hz?")
% Enable phase scan in L2?
guidata(hObject, handles);


% Set L2 RF for acceleration to BC2 and scale all magnets up.
function ACC2_Callback(hObject, eventdata, handles)
set(hObject,'Enable','off')
set(handles.SCL2,'Enable','on')
set(handles.SCL3,'Enable','on')
G  = handles.M(3,1);    % RF gradient (MV/m)
E1 = handles.M(3,2);    % initial energy (GeV)
E2 = handles.M(4,2);    % energy at BC2 (GeV) - after BC1, so use row=4
p1 = handles.M(3,3);    % starting phase (deg)
p2 = handles.M(3,4);    % ending phase (deg)
dp = handles.M(3,5);    % phase steps (deg)
% Get all DB names of QUAD, XCOR, YCOR, BEND, BTRM, & SSA in L2 (BCX14+ thru BCX24)
% Get present E0 and BDES at each magnet (L2)
% Turn off beam at laser
% Turn ON all SSA's in L2
% Insert, or check is inserted, the BC2 collimator (block beam)
% Scale each magnet BDES by ratio of: E2/E0 (Btrim?)
% TRIM all magnets
% Turn on beam at 1 Hz only (dialog box asks "ready for beam at 1 Hz?")
guidata(hObject, handles);


% Scale all L3 magnets and set all of its RF off up to DOG-leg.
function SCL3_Callback(hObject, eventdata, handles)
set(hObject,'Enable','off')
set(handles.SCL1,'Enable','on')
set(handles.ACC1,'Enable','on')
set(handles.SCL2,'Enable','on')
set(handles.ACC2,'Enable','on')
contents = cellstr(get(handles.PM41,'String'));
handles.CM0 = contents{get(handles.PM41,'Value')};
contents = cellstr(get(handles.PM42,'String'));
handles.cav0 = contents{get(handles.PM42,'Value')};
handles.CM_cav0 = [handles.CM0 '-' handles.cav0];
handles.row = 4;    % default to scanning a cavity on 4th row (Linac-3)
set(handles.SCAN,'String',['Scan: ' handles.CM_cav0])
set(handles.RFONOFF,'String',[handles.CM_cav0 ' RF ON'])
handles = update(hObject,handles);
Ec = handles.M(4,2);    % coasting energy (GeV)
% Check beam is accelerating in L2 up to BC2 (i.e., ACC2 has been run)
% Get all DB names of QUAD, XCOR, YCOR, BEND, BTRM, & SSA in L3 (BCX24+ thru BRB2)
% Get present E0 and BDES at each magnet (L3)
% Turn off beam at laser
% Turn off all SSA's in L3
% Insert, or check is inserted, the CEDOG collimator (block beam)
% Scale down each magnet BDES by ratio of: Ec/E0 (Btrim?)
% TRIM all magnets
% Turn on beam at 1 Hz only (dialog box asks "ready for beam at 1 Hz?")
% Enable phase scan in L3?
guidata(hObject, handles);


% Scan RF phase of selected cavity and plot BPM response.
function SCAN_Callback(hObject, eventdata, handles)

if handles.s_L1_LH == 0 || handles.a_L1_LH == 1
    warning = questdlg ('"Scale L1-LH" has not been excecuted and/or "Acc. L1-LH" has been excecuted. Would you like to proceed?','Warning!!','Yes','No','No')
    if strcmpi(warning,'No') || strcmpi(warning,'')
        return
    end
end

set(handles.SCAN,'BackgroundColor','white')
drawnow
R = handles.M(handles.row,:)       % Grad, E, p1, p2, dp
p = R(3):R(5):R(4);                 % phase settings array (deg)
y = sind(p) + cosd(p+10);           % temporary test plot
plot(p,y,'b-',p,y,'or')             % temp.
xlabel('RF Phase (deg)')            % temp.
ylabel('BPM Pos. Reading (mm)')     % temp.
t = get_time;                       % temp.
title([handles.CM_cav0 ' (' t ')']) % temp.
enhance_plot                        % temp.
BPMpvs = handles.BPMpvs(handles.row,:); % BPM PV names for this scan
% Turn on beam (if not already - warning? - rate?)
% Turn on selected cavity SSA (or warn if it's broken)
disp(['Turn on SSA for cavity ' handles.CM_cav0])
disp(['Setting Gradient to ' num2str(R(1)) ' MV/m'])
% Verify beam is on downstream high-dispersion BPM
warning = questdlg (['Turn on beam to BC1 BPM at 10Hz, 20-50 pC and ' num2str(R(2)) ' GeV?'],'Warning!!','Yes','No','No')
if strcmpi(warning,'Yes')
    disp(['Turning on beam to BC1 BPM at 10Hz, 20-50 pC and ' num2str(R(2)) ' GeV'])
end
% Read and save present phase (p0) and gradient (G0) of selected cavity
p0 = handles.M_cav{1,2};%Update this
G0 = handles.M_cav{1,3};%Update this
disp(['Cavity ' handles.CM_cav0 ' values: p0 = ' num2str(p0) ' G0 = ' num2str(G0)])
% Set gradient to Table value (e.g., 2 MV/m in L1)
% Scan RF phase from p1 to p2 in dp steps (loop)
% 
data = ['BPMS:IN20:731:X   ';'KLYS:LI21:71:PHAS ';'BPMS:IN20:731:TMIT'];
celldata = cellstr(data);
count = 1;
for p = R(3)+p0:R(5):R(4)+p0
    disp(['Phase = ' num2str(p)])
    %lcaput(p) to do
    %pause(1) %The user should set this value. Add to the panel
    var(1:3) = lcaGetSmart(celldata,0,'double')
    M(count,1) = var(1);
    M(count,2) = var(2) + p; %P added because all var(2) are "0" for the moment
    M(count,3) = var(3)/1.0e+9; %Is this time in nanoseconds?
    %lcaGetSmart('BPMS:IN20:731:X',0,'double') % get BPM data... (in loop)
    count = count + 1;
end
M(:,2)
j = 1
LLS(transpose(M(:,2)),transpose(M(:,1)),handles.CM_cav0,R)
[x,y] = handles.cav{7}.scan(R)
% 
% Restore initial RF phase (p0)
% Restore initial gradient (G0)
% Turn off (set G=0?) selected SSA
% Set beam to 1 Hz? (minimze losses between scans)
% Fit cos + sin + offset curve (BPM pos. vs. phase)
% Plot data and fit (label with dates, CM, cavity, etc)
%plot(M(:,2),M(:,1),'or')
% Update phase and gradient PVs with new calib's (set phase at crest)
% Post a message on panel (e.g., "data OK")
str = ['Finished phase scan of: ' handles.CM_cav0];
set(handles.MSG,'String',str)
pause(1)    % not needed if real scan
set(handles.SCAN,'BackgroundColor','green')     % done with scan
drawnow
guidata(hObject, handles);


% Set N pulses to average BPM reading.
function NAVG_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of NAVG as text
%        str2double(get(hObject,'String')) returns contents of NAVG as a double
handles.Navg = str2double(get(hObject,'String'));
guidata(hObject, handles);
%
% --- Executes during object creation, after setting all properties.
function NAVG_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Turn ON or OFF the selected cavity.
function RFONOFF_Callback(hObject, eventdata, handles)
v = get(hObject,'Value');   % 1 or 0
if v == 0
  set(hObject,'BackgroundColor','yellow');
  set(hObject,'String',[handles.CM_cav0 ' RF ON']);
  handles.RF = 1;   % RF ON for this selected cavity
else
  set(hObject,'BackgroundColor','red');
  set(hObject,'String',[handles.CM_cav0 ' RF OFF']);
  handles.RF = 0;   % RF OFF for this selected cavity
end
drawnow
guidata(hObject, handles);
    

% Switch e- beam ON or OFF.
function BEAMONOFF_Callback(hObject, eventdata, handles)
v = get(hObject,'Value');   % 1 or 0
if v == 0
  set(hObject,'BackgroundColor','green');
  set(hObject,'String','Beam ENABLED');
  handles.beamon = 1;   % enable e- beam
else
  set(hObject,'BackgroundColor','red');
  set(hObject,'String','Beam DISABLED');
  handles.beamon = 0;   % disable e- beam
end
% send on/off to laser shutter
drawnow
guidata(hObject, handles);


% Switch from 1 to 10 Hz, or reverse.
function ONEHZ_Callback(hObject, eventdata, handles)
v = get(hObject,'Value');   % 1 or 0
if v == 0
  set(hObject,'BackgroundColor',[255 153 0]/255);
  set(hObject,'String','10 Hz');
  handles.rate = 10; % allow 10 Hz
else
  set(hObject,'BackgroundColor','red');
  set(hObject,'String','1 Hz');
  handles.rate = 1;  % limit to 1 Hz
end
drawnow
guidata(hObject, handles);


% Print plot to E-log ELOG.
function ELOG_Callback(hObject, eventdata, handles)
% next code taken from Phase-Scans GUI (may not work)...
%
% if ~any(ishandle(handles.exportFig)), return, end
% str=strtok(get(get(findobj(handles.exportFig,'type','axes'),'XLabel'),'String'),' ');
% util_printLog(handles.exportFig,'title',['Phase Scan ' str]);
% dataSave_btn_Callback(hObject,[],handles);



function edit22_Callback(hObject, eventdata, handles)
% hObject    handle to edit22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit22 as text
%        str2double(get(hObject,'String')) returns contents of edit22 as a double


% --- Executes during object creation, after setting all properties.
function edit22_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

