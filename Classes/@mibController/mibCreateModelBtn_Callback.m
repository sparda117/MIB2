function mibCreateModelBtn_Callback(obj, modelType, modelMaterialNames)
% function mibCreateModelBtn_Callback(obj, modelType)
% Create a new model
%
%
% Parameters:
% modelType: [@em optional], can be empty: []; a double with the model type:
% @li 63 - 63 material model
% @li 255 - 255 material model
% modelMaterialNames: [@em optional] can be empty: []; a cell array with names of materials, this parameter is not used for modelType > 255
%
% Return values:
% 
%

%| 
% @b Examples:
% @code mibController.mibCreateModelBtn_Callback();     // create a new model @endcode
 
% Copyright (C) 28.11.2016 Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
%
if nargin < 3; modelMaterialNames = []; end
if nargin < 2; modelType = []; end

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'models are';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

% do nothing is selection is disabled
if obj.mibModel.I{obj.mibModel.Id}.disableSelection == 1
    warndlg(sprintf('The models are switched off!\n\nPlease make sure that the "Disable selection" option in the Preferences dialog (Menu->File->Preferences) is set to "no" and try again...'),'The models are disabled','modal');
    return; 
end

if obj.mibModel.getImageProperty('modelExist') == 1
    button = questdlg(sprintf('!!! Warning !!!\nYou are about to start a new model,\n the existing model will be deleted!\n\n'), 'Start new model', 'Continue', 'Cancel', 'Cancel');
    if strcmp(button, 'Cancel'); return; end
end

if isempty(modelType)
    modelType = mibSelectModelTypeDlg({obj.mibPath});
    if isempty(modelType); return; end
end

wb = waitbar(0, 'Please wait...', 'Name', 'Create model', 'WindowStyle', 'modal');

switch modelType
    case {63, 255}
        obj.mibModel.I{obj.mibModel.Id}.createModel(modelType, modelMaterialNames);
        %obj.mibModel.I{obj.mibModel.Id}.selectedMaterial = 2;
        %obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = 2;
    case 65535
        obj.mibModel.I{obj.mibModel.Id}.createModel(65535);
        %obj.mibModel.I{obj.mibModel.Id}.selectedMaterial = 3;
        %obj.mibModel.I{obj.mibModel.Id}.selectedAddToMaterial = 3;
    case 4294967295
        obj.mibModel.I{obj.mibModel.Id}.createModel(4294967295);
end
waitbar(0.9, wb);

% last selected contour for use with the 'e' button
obj.mibView.lastSegmSelection = [2 1];

obj.updateGuiWidgets();
waitbar(0.95, wb);
obj.mibView.handles.mibModelShowCheck.Value = 1;    % turn on show model checkbox
obj.mibModelShowCheck_Callback();
obj.updateGuiWidgets();

obj.plotImage();
waitbar(1, wb);
delete(wb);
end