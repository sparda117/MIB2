function menuModelsExport_Callback(obj, parameter)
% function menuModelsExport_Callback(obj, parameter)
% callback to Menu->Models->Export
% export the Model layer to the main Matlab workspace
%
% Parameters:
% parameter: a string with destination for the export
% @li 'matlab' - to Matlab workspace
% @li 'imaris' - to Imaris

% Copyright (C) 06.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 

% check for the virtual stacking mode and return
if obj.mibModel.I{obj.mibModel.Id}.Virtual.virtual == 1
    toolname = 'export of models is';
    warndlg(sprintf('!!! Warning !!!\n\nThe %s not yet available in the virtual stacking mode.\nPlease switch to the memory-resident mode and try again', ...
        toolname), 'Not implemented');
    return;
end

global mibPath;
if strcmp(parameter, 'matlab')
    prompt = {'Variable for the structure to keep the model:'};
    title = 'Input a destination variable for export';
    answer = mibInputDlg({mibPath}, prompt, title, 'O');
    if size(answer) == 0; return; end
    
    options.blockModeSwitch = 0;
    O.model = cell2mat(obj.mibModel.getData4D('model', 4, NaN, options));

    O.modelMaterialNames = obj.mibModel.I{obj.mibModel.Id}.modelMaterialNames;
    O.modelMaterialColors = obj.mibModel.I{obj.mibModel.Id}.modelMaterialColors;
    O.modelType = obj.mibModel.I{obj.mibModel.Id}.modelType;    % store the model type

    if obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabelsNumber() > 1  % save annotations
        [O.labelText, O.labelValue, O.labelPosition] = obj.mibModel.I{obj.mibModel.Id}.hLabels.getLabels(); %#ok<NASGU,ASGLU>
    end
    
    assignin('base', answer{1}, O);
    disp(['Model export: created structure ' answer{1} ' in the Matlab workspace']);
else
    options.type = 'model';
    % define index of material to model, NaN - model all
    if obj.mibModel.showAllMaterials == 1    % all materials
        options.modelIndex = NaN;
    else
        options.modelIndex = obj.mibModel.I{obj.mibModel.Id}.getSelectedMaterialIndex();
    end
    obj.mibModel.connImaris = mibSetImarisDataset(obj.mibModel.I{obj.mibModel.Id}, obj.mibModel.connImaris, options);
end
end