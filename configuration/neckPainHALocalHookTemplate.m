function continuousHALocalHook

%  continuousHALocalHook
%
% Configure things for working on the  continuousHA project.
%
% For use with CHOP network computers, need appropriate access to run
% For use with ToolboxToolbox
% If you 'git clone' continuousHA into your ToolboxToolbox "projectRoot"
% folder, then run in MATLAB
%   tbUseProject('continuousHA')
% ToolboxToolbox will set up continuousHA and its dependencies on
% your machine.
%
% As part of the setup process, ToolboxToolbox will copy this file to your
% ToolboxToolbox localToolboxHooks directory (minus the "Template" suffix).
% The defalt location for this would be
%   ~/localToolboxHooks/continuousHALocalHook.m
%
% Each time you run tbUseProject('continuousHA'), ToolboxToolbox will
% execute your local copy of this file to do setup for continuousHA.
%
% You should edit your local copy with values that are correct for your
% local machine, for example the output directory location.
%


%% Say hello.
projectName = 'continuousHA';

%% Delete any old prefs
if (ispref(projectName))
    rmpref(projectName);
end

%% Specify base paths for materials and data (set up for CPG only)
[~, userID] = system('whoami');
userID = strtrim(userID);

Pfizer_dataBasePath = ['/Users/' userID '/OneDrive - Children"s Hospital of Philadelphia/Research/Pfizer Registry/Data/continuousHA/'];
contHA_analysisBasePath = ['/Users/' userID '/OneDrive - Children''s Hospital of Philadelphia/Research/Pfizer Registry/Analysis/continuousHA'];

%% Specify where output goes (for mac)

% Code to run on Mac plaform
setpref(projectName,'pfizerDataPath', Pfizer_dataBasePath);
setpref(projectName,'contHaAnalysisPath', contHA_analysisBasePath);

