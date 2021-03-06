classdef mibCropController  < handle
    % @type mibCropController class is resposnible for showing the dataset
    % crop window, available from MIB->Menu->Dataset->Crop 
    
	% Copyright (C) 09.02.2017, Ilya Belevich, University of Helsinki (ilya.belevich @ helsinki.fi)
	% 
	% part of Microscopy Image Browser, http:\\mib.helsinki.fi 
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
	%
	% Updates
	% 
    
    properties
        mibModel
        % handles to the model
        View
        % handle to the view
        listener
        % a cell array with handles to listeners
        roiPos
        % a cell array with position of the ROI for crop
        % obj.roiPos{1} = [1, width, 1, height, 1, depth, 1, time];
        mibImageAxes
        % handle to mibView. mibImageAxes, main image axes of MIB
        currentMode
        % a string with the selected crop mode: 'interactiveRadio','manualRadio','roiRadio'
    end
    
    events
        %> Description of events
        closeEvent
        % event firing when window is closed
    end
    
    methods (Static)
        function ViewListner_Callback2(obj, src, evnt)
            switch evnt.EventName
                case {'updateGuiWidgets', 'updateROI'}
                    obj.updateWidgets();
            end
        end
    end
    
    methods
        function obj = mibCropController(mibModel, mibImageAxes)
            obj.mibModel = mibModel;    % assign model
            obj.mibImageAxes = mibImageAxes;
            guiName = 'mibCropGUI';
            obj.View = mibChildView(obj, guiName); % initialize the view
            
            obj.currentMode	= 'manualRadio';
            
			obj.updateWidgets();
			
			% add listner to obj.mibModel and call controller function as a callback
             % option 1: recommended, detects event triggered by mibController.updateGuiWidgets
             obj.listener{1} = addlistener(obj.mibModel, 'updateGuiWidgets', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes updateGuiWidgets
             obj.listener{2} = addlistener(obj.mibModel, 'updateROI', @(src,evnt) obj.ViewListner_Callback2(obj, src, evnt));    % listen changes in number of ROIs
        end
        
        function closeWindow(obj)
            % closing mibCropController  window
            if isvalid(obj.View.gui)
                delete(obj.View.gui);   % delete childController window
            end
            
            % delete listeners, otherwise they stay after deleting of the
            % controller
            for i=1:numel(obj.listener)
                delete(obj.listener{i});
            end
            
            notify(obj, 'closeEvent');      % notify mibController that this child window is closed
        end
        
        function updateWidgets(obj)
            % function updateWidgets(obj)
            % update all widgets of the current window
            obj.View.handles.wEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('width'))];
            obj.View.handles.hEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('height'))];
            obj.View.handles.zEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('depth'))];
            obj.View.handles.tEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('time'))];
            obj.roiPos{1} = NaN;
            
            [numberOfROI, indicesOfROI] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI(0);     % get all ROI
            if numberOfROI == 0
                 obj.View.handles.roiRadio.Enable = 'off';
                 if strcmp(obj.currentMode, 'roiRadio')     % disable roi mode when no roi
                    obj.currentMode = 'manualRadio';
                    obj.View.handles.manualRadio.Value = 1;
                 end
            end
            obj.radio_Callback(obj.View.handles.(obj.currentMode));
            
            list{1} = 'All';
            i=2;
            for idx = indicesOfROI
                list(i) = obj.mibModel.I{obj.mibModel.Id}.hROI.Data(idx).label; %#ok<AGROW>
                i = i + 1;
            end
            obj.View.handles.roiPopup.String = list;
            
            if numel(list) > 1
                obj.View.handles.roiPopup.Value = max([obj.mibModel.I{obj.mibModel.Id}.selectedROI+1 2]);
                obj.View.handles.roiRadio.Enable = 'on';
            else
                obj.View.handles.roiPopup.Value = 1;
            end
        end
        
        function radio_Callback(obj, hObject)
            % function radio_Callback(obj, hObject)
            % callback for selection of crop mode
            %
            % Parameters:
            % hObject: a handle to selected radio button to choose the crop mode
            % @li handles.interactiveRadio - interactive
            % @li handles.manualRadio - manual
            % @li handles.roiRadio - from selected ROI
            
            mode = hObject.Tag;
            
            obj.View.handles.roiPopup.Enable = 'off';
            obj.View.handles.wEdit.Enable = 'off';
            obj.View.handles.hEdit.Enable = 'off';
            obj.View.handles.zEdit.Enable = 'off';
            
            if obj.mibModel.getImageProperty('time') > 1
                obj.View.handles.tEdit.Enable = 'on';
            else
                obj.View.handles.tEdit.Enable = 'off';
            end
            if strcmp(mode,'interactiveRadio')
                text = sprintf('Interactive mode allows to draw a rectangle that will be used for cropping.To start, press the Crop button and use the left mouse button to draw an area, double click over the area to crop');
                obj.editboxes_Callback();
            elseif strcmp(mode,'manualRadio')
                obj.View.handles.wEdit.Enable = 'on';
                obj.View.handles.hEdit.Enable = 'on';
                obj.View.handles.zEdit.Enable = 'on';
                text = sprintf('In the manual mode the numbers entered in the edit boxes below will be used for cropping');
                obj.editboxes_Callback();
            elseif strcmp(mode,'roiRadio')
                obj.View.handles.roiPopup.Enable = 'on';
                text = sprintf('Use existing ROIs to crop the image');
                obj.roiPopup_Callback();
            end
            obj.View.handles.descriptionText.String = text;
            obj.View.handles.descriptionText.TooltipString = text;
            obj.currentMode = mode;
        end
        
        function editboxes_Callback(obj)
            % function editboxes_Callback(obj)
            % update parameters of obj.roiPos based on provided values
            
            str2 = obj.View.handles.wEdit.String;
            obj.roiPos{1}(1) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(2) = max(str2num(str2)); %#ok<ST2NM>
            str2 = obj.View.handles.hEdit.String;
            obj.roiPos{1}(3) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(4) = max(str2num(str2)); %#ok<ST2NM>
            str2 = obj.View.handles.zEdit.String;
            obj.roiPos{1}(5) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(6) = max(str2num(str2)); %#ok<ST2NM>
            str2 = obj.View.handles.tEdit.String;
            obj.roiPos{1}(7) = min(str2num(str2)); %#ok<ST2NM>
            obj.roiPos{1}(8) = max(str2num(str2)); %#ok<ST2NM>
        end
        
        function roiPopup_Callback(obj)
            % function roiPopup_Callback(obj)
            % callback for change of obj.View.handles.roiPopup with the
            % list of ROIs
            
            val = obj.View.handles.roiPopup.Value - 1;
            
            str2 = obj.View.handles.tEdit.String;
            tMin = min(str2num(str2)); %#ok<ST2NM>
            tMax = max(str2num(str2)); %#ok<ST2NM>
            if val == 0
                [number, roiIndices] = obj.mibModel.I{obj.mibModel.Id}.hROI.getNumberOfROI(0);
                i = 1;
                for idx=roiIndices
                    obj.roiPos{i} = obj.mibModel.I{obj.mibModel.Id}.getROIBoundingBox(idx);
                    obj.roiPos{i}(7:8) = [tMin, tMax];
                    i = i + 1;
                end
                obj.View.handles.wEdit.String = 'Multi';
                obj.View.handles.hEdit.String = 'Multi';
                obj.View.handles.zEdit.String = 'Multi';
            else
                bb{1} = obj.mibModel.I{obj.mibModel.Id}.getROIBoundingBox(val);
                obj.View.handles.wEdit.String = [num2str(bb{1}(1)) ':', num2str(bb{1}(2))];
                obj.View.handles.hEdit.String = [num2str(bb{1}(3)) ':', num2str(bb{1}(4))];
                obj.View.handles.zEdit.String = [num2str(bb{1}(5)) ':', num2str(bb{1}(6))];
                obj.roiPos{1} = bb{1};
                obj.roiPos{1}(7:8) = [tMin, tMax];
            end
        end
        
        function resetBtn_Callback(obj)
            % function resetBtn_Callback(obj)
            % reset widgets based on current image sizes
            obj.View.handles.wEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('width'))];
            obj.View.handles.hEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('height'))];
            obj.View.handles.zEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('depth'))];
            obj.View.handles.tEdit.String = ['1:' num2str(obj.mibModel.getImageProperty('time'))];
            
            obj.roiPos{1} = [1, obj.mibModel.getImageProperty('width'), 1, obj.mibModel.getImageProperty('height'),...
                1, obj.mibModel.getImageProperty('depth') 1, obj.mibModel.getImageProperty('time')];
            
            obj.radio_Callback(obj.View.handles.manualRadio);
        end
        
        function cropBtn_Callback(obj, hObject)
            % function cropBtn_Callback(obj, hObject)
            % make the crop
            % 
            % Parameters:
            % hObject: handle to the pressed button, handles.croptoBtn or
            % handles.cropBtn
            
            global mibPath; % path to mib installation folder
            
            if obj.View.handles.interactiveRadio.Value    % interactive
                obj.View.gui.Visible = 'off';
                
                obj.mibModel.disableSegmentation = 1;  % disable segmentation
                
                h =  imrect(obj.mibImageAxes);
                new_position = wait(h);
                delete(h);
                obj.mibModel.disableSegmentation = 0;    % re-enable selection switch 
                
                if isempty(new_position)
                    obj.View.gui.Visible = 'on';
                    return;
                end
                
                % [xmin, ymin, width, height]
                options.blockModeSwitch = 0;
                [height, width, ~, ~] = obj.mibModel.I{obj.mibModel.Id}.getDatasetDimensions('selection', NaN, 0, options);

                % make positive x1 and y1 and convert from [x1, y1 width, height] to [x1, y1, x2, y2]
                new_position(3) = new_position(3) + new_position(1);    % xMax
                new_position(4) = new_position(4) + new_position(2);    % yMax
                if new_position(1) < 0; new_position(1) = max([new_position(1) 0.5]); end             % xMin
                if new_position(2) < 0; new_position(2) = max([new_position(2) 0.5]); end             % yMin
                
                % [xmin, ymin, xmax, ymax]
                [position(1), position(2)] = obj.mibModel.convertMouseToDataCoordinates(new_position(1), new_position(2), 'shown');  % x1, y1
                [position(3), position(4)] = obj.mibModel.convertMouseToDataCoordinates(new_position(3), new_position(4), 'shown'); % x2, y2
                position = ceil(position);
                
                % fix x2 and y2
                if position(3) > width; position(3) = width; end
                if position(4) > height; position(4) = height; end
                 
                if obj.mibModel.I{obj.mibModel.Id}.orientation == 4 % xy plane
                    crop_factor = [position(1:2) position(3)-position(1)+1 position(4)-position(2)+1 1 obj.mibModel.I{obj.mibModel.Id}.depth]; % x1, y1, dx, dy, z1, dz
                elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 1 % xz plane
                    crop_factor = [position(2) 1 position(4)-position(2)+1 obj.mibModel.I{obj.mibModel.Id}.height position(1) position(3)-position(1)+1]; % x1, y1, dx, dy, z1, dz
                elseif obj.mibModel.I{obj.mibModel.Id}.orientation == 2 % yz plane
                    crop_factor = [1 position(2) obj.mibModel.I{obj.mibModel.Id}.width position(4)-position(2)+1 position(1) position(3)-position(1)+1]; % x1, y1, dx, dy, z1, dz
                end
                obj.View.gui.Visible = 'on';
            elseif ~isnan(obj.roiPos{1})
                x1 = obj.roiPos{1}(1);
                x2 = obj.roiPos{1}(2);
                y1 = obj.roiPos{1}(3);
                y2 = obj.roiPos{1}(4);
                z1 = obj.roiPos{1}(5);
                z2 = obj.roiPos{1}(6);
                crop_factor = [x1,y1,x2-x1+1,y2-y1+1,z1,z2-z1+1];
            else
                msgbox('Oops, not implemented yet!','Multiple ROI crop','warn');
                return;
            end
            
            if strcmp(hObject.Tag, 'croptoBtn')
                bufferId = obj.mibModel.maxId;
                for i=1:obj.mibModel.maxId-1
                    if strcmp(obj.mibModel.I{i}.meta('Filename'), 'none.tif')
                        bufferId = i;
                        break;
                    end
                end
                prompts = {'Enter the destination buffer:'};
                defAns = {arrayfun(@(x) {num2str(x)}, 1:obj.mibModel.maxId)};
                defAns{1}(end+1) = {bufferId};
                title = 'Crop dataset to';
                answer = mibInputMultiDlg({mibPath}, prompts, defAns, title);
                if isempty(answer); return; end
                bufferId = str2double(answer{1});
                
                % copy dataset to the destination buffer
                obj.mibModel.mibImageDeepCopy(bufferId, obj.mibModel.Id);
            else
                bufferId = obj.mibModel.Id;
            end
            
            crop_factor = [crop_factor obj.roiPos{1}(7) obj.roiPos{1}(8)-obj.roiPos{1}(7)+1];
            obj.mibModel.I{bufferId}.disableSelection = obj.mibModel.preferences.disableSelection;  % should be before cropDataset
            result = obj.mibModel.I{bufferId}.cropDataset(crop_factor);
            if result == 0; return; end
            obj.mibModel.I{bufferId}.hROI.crop(crop_factor);
            obj.mibModel.I{bufferId}.hLabels.crop(crop_factor);
            log_text = ['ImCrop: [x1 y1 dx dy z1 dz t1 dt]: [' num2str(crop_factor) ']'];
            obj.mibModel.I{bufferId}.updateImgInfo(log_text);

%             
%             if strcmp(get(hObject, 'tag'), 'croptoBtn')
% 
%             else
%                 obj.updateWidgets();
%             end
            eventdata = ToggleEventData(bufferId);  
            notify(obj.mibModel, 'newDataset', eventdata);  % notify newDataset with the index of the dataset
            if ~strcmp(hObject.Tag, 'croptoBtn')
                eventdata = ToggleEventData(1);
                notify(obj.mibModel, 'plotImage', eventdata);
            end
            
            %obj.closeWindow();
            obj.updateWidgets();
        end
        
    end
end