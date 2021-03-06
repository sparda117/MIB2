function mibBufferToggleContext_Callback(obj, parameter, buttonID)
% function mibBufferToggleContext_Callback(obj, parameter, buttonID)
% callback function for the popup menu of the buffer buttons in the upper
% part of the @em Directory @em contents panel. This callback is triggered
% from all those buttons.
% 
% Parameters:
% parameter: - a string that defines options:
% - @b duplicate - duplicate the dataset to another buffer
% - @b sync_xy - synchronize datasets with another dataset in XY
% - @b sync_xyz - synchronize datasets with another dataset in XYZ
% - @b sync_xyzt - synchronize datasets with another dataset in XYZT
% - @b clear - delete the dataset
% - @b clearAll - delete all datasets
% buttonID: - a number (from 1 to 9) of the pressed toggle button.

% Copyright (C) 04.11.2016, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% Updates
% 
global mibPath; % path to mib installation folder

switch parameter
    case 'duplicate'    % duplicate dataset to a new position
        destinationButton = obj.mibModel.maxId;
        for i=1:obj.mibModel.maxId-1
            if strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif')
                destinationButton = i;
                break;
            end
        end
        prompts = {'Enter the destination buffer:'};
        defAns = {arrayfun(@(x) {num2str(x)}, 1:obj.mibModel.maxId)};
        defAns{1}(end+1) = {destinationButton};
        title = 'Duplicate dataset';
        answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
        if isempty(answer); return; end
        destinationButton = str2double(answer{1});

        if ~strcmp(obj.mibModel.I{destinationButton}.meta('Filename'), 'none.tif')
            button = questdlg(sprintf('You are goind to overwrite dataset in buffer %d\n\nAre you sure?', destinationButton), ...
                '!! Warning !!', 'Overwrite', 'Cancel', 'Cancel');
            if strcmp(button, 'Cancel'); return; end
        end
        
        obj.mibModel.mibImageDeepCopy(destinationButton, buttonID);
        
        bufferId = sprintf('mibBufferToggle%d', destinationButton);
        if ismac()
            obj.mibView.handles.(bufferId).ForegroundColor = [0 1 0];   % make green
        else
            obj.mibView.handles.(bufferId).BackgroundColor = [0 1 0]; % make green
        end
        obj.mibView.handles.(bufferId).TooltipString = obj.mibModel.I{i}.meta('Filename');     % make a tooltip as filename
    case {'sync_xy', 'sync_xyz', 'sync_xyzt'}  % synchronize view with another opened dataset
        destinationButton = obj.mibModel.maxId;
        for i=1:obj.mibModel.maxId-1
            if ~strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif') && i ~= buttonID
                destinationButton = i;
                break;
            end
        end
        prompts = {'Enter number of the dataset to synchronize with:'};
        defAns = {arrayfun(@(x) {num2str(x)}, 1:obj.mibModel.maxId)};
        defAns{1}(end+1) = {destinationButton};
        title = 'Synchronize dataset';
        answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
        if isempty(answer); return; end
        destinationButton = str2double(answer{1});

        if obj.mibModel.I{buttonID}.orientation ~= obj.mibModel.I{destinationButton}.orientation
            errordlg(sprintf('The datasets should be in the same orientation!\n\nFor example, switch orientation of both datasets to XY (the XY button in the toolbar) and try again'),'Wrong buffer'); return;
        end
        
        if obj.mibModel.I{buttonID}.volren.show == 0
            [axesX, axesY] = obj.mibModel.getAxesLimits(destinationButton);
            obj.mibModel.setAxesLimits(axesX, axesY, buttonID);
            obj.mibModel.setMagFactor(obj.mibModel.getMagFactor(destinationButton), buttonID);
            
            if strcmp(parameter, 'sync_xyz') || strcmp(parameter, 'sync_xyzt')   % sync in z, t as well
                destZ = obj.mibModel.I{destinationButton}.slices{obj.mibModel.I{destinationButton}.orientation}(1);
                if destZ > obj.mibModel.I{buttonID}.dim_yxczt(obj.mibModel.I{buttonID}.orientation)
                    warndlg(sprintf('The second dataset has the Z value higher than the Z-dimension of the first dataset!\n\nThe synchronization was done in the XY mode.'),'Dimensions mismatch!');
                    return;
                end
                if obj.mibModel.I{buttonID}.depth > 1
                    obj.mibView.handles.mibChangeLayerEdit.String = destZ;
                    obj.mibChangeLayerEdit_Callback();
                end
                if strcmp(parameter, 'sync_xyzt') && obj.mibModel.I{buttonID}.time > 1
                    destT = obj.mibModel.I{destinationButton}.slices{5}(1);
                    if destT > obj.mibModel.I{buttonID}.time
                        warndlg(sprintf('The second dataset has the T value higher than the T-dimension of the first dataset!\n\nThe synchronization was done in the XYZ mode.'),'Dimensions mismatch!');
                        obj.plotImage(0);
                        return;
                    end
                    obj.mibView.handles.mibChangeTimeEdit.String = destT;
                    obj.mibChangeTimeEdit_Callback();
                end
            end
        else
             obj.mibView.volren{buttonID}.viewer_matrix = obj.mibView.volren{destinationButton}.viewer_matrix;
        end
        obj.plotImage(0);
    case 'clear'    % clear dataset
        mibImageOptions = struct();
        mibImageOptions.virtual = obj.mibModel.I{buttonID}.Virtual.virtual;
        
        obj.mibView.gui.WindowButtonMotionFcn = [];  % have to turn off windowbuttonmotionfcn, otherwise give error after delete(obj.mibView.handles.Img{button}.I); during mouse movement
        obj.mibModel.I{buttonID}.closeVirtualDataset();    % close the virtual datasets 
        
        delete(obj.mibModel.I{buttonID});
        obj.mibModel.I{buttonID} = mibImage([], [], mibImageOptions);    % create instance for keeping images;
        
        eventdata = ToggleEventData(buttonID);
        notify(obj.mibModel, 'newDataset', eventdata);
        
        if buttonID == obj.mibModel.Id                       % delete the currently shown dataset
            obj.plotImage(1);
        end
    case 'clearAll'     % clear all stored datasets
        button = questdlg(sprintf('Warning!\n\nYou are going to clear all buffered datasets!\nContinue?'),...
            'Clear buffer','Continue','Cancel','Cancel');
        if strcmp(button, 'Cancel'); return; end
        
        % initialize image buffer with dummy images
        obj.mibModel.Id = 1;   % number of the selected buffer
        obj.mibView.gui.WindowButtonMotionFcn = [];  % have to turn off windowbuttonmotionfcn, otherwise give error after delete(obj.mibView.handles.Img{button}.I); during mouse movement
        for button=1:obj.mibModel.maxId
            mibImageOptions = struct();
            mibImageOptions.virtual = obj.mibModel.I{button}.Virtual.virtual;
            obj.mibModel.I{button}.closeVirtualDataset();    % close the virtual datasets
            
            delete(obj.mibModel.I{button});
            obj.mibModel.I{button} = mibImage([],[],mibImageOptions);    % create instanse for keeping images;
            obj.updateAxesLimits('resize', button);
            bufferId = sprintf('mibBufferToggle%d', button);
            obj.mibView.handles.(bufferId).Value = 0;
        end
        obj.mibView.handles.mibBufferToggle1.Value = 1;
        notify(obj.mibModel, 'newDataset');  % notify about a new dataset
        obj.plotImage(1);
end
end
