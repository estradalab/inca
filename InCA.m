classdef InCA < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        %High level containers
        UIFigure                        
        Toolstrip      
        AnalysisTabs
        ViewerTabs
        
        %Mid level containers
        OverviewTab
        CentroidTab
        FourierFitDataTab
        FourierDecompositionTab
        SphericalHarmonicsTab
        ViewerTab
        EvolutionOverlayTab
        
        %Low level containers
        DecomposedPlotsPanel
        
        %Toolstrip buttons
        NewButton
        BatchButton
        OpenButton
        SaveButton
        DetectButton
        MaskPreviewButton
        AnalyzeButton
        ExportButton
        IMRButton
        
        %Toolstrip switches
        IFFToggle
        IFFToggleLabel
        MultiToggle   
        MultiToggleLabel
        RDBWToggle      
        RDBWToggleLabel
        FrameWarningToggle
        FrameIgnoreLabel
        FourierFitLabel
        FourierFitToggle
        
        %Dropdowns
        RotationAxis
        RotAxisLabel
        PreProcessMethod
        PreProcessLabel
        NumTerms
        NumTermsLabel
        FitType 
        FitTypeLabel
        PlotAxes
        PlotAxesLabel
        
        %EditFields
        MinArcLengthLabel
        MinArcLengthField
        MaxTermsLabel
        MaxTermsField
        TermsofInterestLabel
        TermsofInterestField
        MicronPxLabel
        MicronPxField
        FPSLabel
        FPSField
        JumpFrameLabel
        JumpFrameField
        TargetFrameLabel
        TargetFrameField
        TermstoDecomposeLabel
        TermstoDecomposeField
        
        %Plots
        RadiusPlot
        TwoDimensionalPlot
        ThreeDimensionalPlot
        CentroidPlot
        EvolutionPlot
        MainPlot
        AsphericityPlot
        VelocityPlot
        
        %Labels
        EvolutionFirst
        EvolutionLast
        CentroidFirst
        CentroidLast
        FourierSecond
        FourierLast
        
        %Other Buttons
        NextFrameButton
        PreviousFrameButton
        FrameInspectorButton
        DecomposeButton
        
        %Misc
        FourierColorMap
    end

    properties (Access = public)
        frames
        mask
        maskInformation
        ignoreFrames
        currentFrame
        radius
        area
        perimeter
        surfaceArea
        centroid
        volume
        velocity
        numFrames
        convertedPlotSet
        frameInterval
        batchmode
    end
    
    methods (Access = private)
        
        function checkVersion(app)
            try
                weboptions.TimeOut = 10;
                newestVersion = str2double(string(webread('https://raw.githubusercontent.com/estradalab/inca/master/version.txt')));
                if newestVersion > 16
                    uialert(app.UIFigure, 'A newer version of InCA is available. An update is recommended.', 'Newer version detected', 'Icon', 'warning');
                end
            catch me
                uialert(app.UIFigure, me.message, append('Version Check Error: ', me.identifier), 'Icon', 'error');
            end
        end
        
        function generatePreviews(app, frames, mask)
            %% A function to generate mask overlay previews for InCA.
            
            %Get the size of the image and the number of frames
            [height, width, app.numFrames] = size(frames);
            
            %Get the size of the InCA main window
            parentPos = app.UIFigure.Position;
            
            %Create a panel on top of the existing window to house the mask previews
            MaskOverlayPreviewPanel = uipanel('Parent', app.UIFigure, 'BorderType', 'line', 'Position', [50, 50, parentPos(3) - 100, parentPos(4) - 100], ...
                'BackgroundColor', [0.1 0.1 0.1], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
            parentPos = MaskOverlayPreviewPanel.Position;
            parentPos(3) = parentPos(3).*0.99;
            parentPos(4) = parentPos(4).*0.99;
            
            %Create a panel within the mask preview panel to house the thumbnails
            ScrollPanel = uipanel('Parent', MaskOverlayPreviewPanel, 'BorderType', 'none', 'Position', [1 1, parentPos(3)/5, parentPos(4) - 5],...
                'BackgroundColor', [0 0 0], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
            panelPos = ScrollPanel.Position;
            
            %Create the main viewer for the masks
            mainAxes = uiaxes(MaskOverlayPreviewPanel, 'AmbientLightColor', [0 0 0], 'FontName', 'Roboto', 'FontSize', 12, 'XColor', [1 1 1], ...
                'YColor', [1 1 1], 'Color', [0 0 0], 'BackgroundColor', [0 0 0], 'Position', [parentPos(3)/5, 55, parentPos(3)*4/5, parentPos(4) - 60]);
            
            %Create the requried buttons: close, accept, reject, next, and previous
            
            %Previous Button
            uibutton(MaskOverlayPreviewPanel, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'baseline_skip_previous_white_48dp.png', 'IconAlignment', 'top', 'Text', 'PREVIOUS', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [parentPos(3)/5 + 5, 5, 100, 50], 'BackgroundColor', [0, 0.29, 1], "ButtonPushedFcn", {@previousClicked});
            %Next Button
            uibutton(MaskOverlayPreviewPanel, 'push', 'Text', 'NEXT', 'FontName', 'Roboto', 'FontSize', 10, 'FontColor', [1 1 1], 'Icon', ...
                'baseline_skip_next_white_48dp.png', 'IconAlignment', 'top', 'VerticalAlignment', 'bottom', 'Position', ...
                [parentPos(3) - 100 - 5, 5, 100, 50], 'BackgroundColor', [0 0.29 1], "ButtonPushedFcn", {@nextClicked, app.numFrames});
            %Reject Button
            uibutton(MaskOverlayPreviewPanel, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, 'Icon', 'baseline_close_white_48dp.png', 'IconAlignment', 'top', 'Text',...
                'REJECT', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], 'ButtonPushedFcn', {@rejectClicked, app}, 'Position', ...
                [parentPos(3)/5 + 110 ,5, 100, 50], 'BackgroundColor', [176 0 32]./255);
            %Accpet Button
            uibutton(MaskOverlayPreviewPanel, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, 'Icon', 'baseline_done_white_48dp.png', 'IconAlignment', 'top', 'Text',...
                'ACCEPT', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], 'ButtonPushedFcn', {@acceptClicked, app}, 'Position', ...
                [parentPos(3) - 210 ,5, 100, 50], 'BackgroundColor', [8 226 55]./255);
            %Close Button
            uibutton(MaskOverlayPreviewPanel, 'push', 'FontName', 'Roboto Medium', 'FontSize', 14, 'Text', 'SAVE & CLOSE', 'FontColor', [1 1 1], 'ButtonPushedFcn', ...
                {@closeClicked, MaskOverlayPreviewPanel},'Position', [parentPos(3)/5 + (parentPos(3)*2/5 - 50), 5, 100, 50], 'BackgroundColor', [0 0.29 1]);
            
            
            %Populate the thumbnail panel
            for i = 1:app.numFrames
                index = (app.numFrames + 1) - i;
                if isempty(find(app.ignoreFrames == index, 1))
                    if any(any(mask(:, :, index)))
                        uiimage(ScrollPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
                            labeloverlay(frames(:, :, index), mask(:, :, index)), "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
                            "ImageClickedFcn", {@imageClicked},'Tooltip', "Click to ignore frame " + num2str(index) + " during calculations", 'Tag', num2str(index));
                    else
                        image = zeros(size(frames(:, :, index)));
                        image(:, :, 3) = frames(:, :, index);
                        image = hsv2rgb(image);
                        uiimage(ScrollPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
                            image, "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
                            "ImageClickedFcn", {@imageClicked},'Tooltip', "Click to ignore frame " + num2str(index) + " during calculations", 'Tag', num2str(index));
                    end
                else
                    if any(any(mask(:, :, index)))
                        uiimage(ScrollPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
                            labeloverlay(frames(:, :, index), ones(size(frames(:, :, index))), 'Colormap', 'autumn'), "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
                            "ImageClickedFcn", {@imageClicked},'Tooltip', "This frame will be ignored during bubble analysis", 'Tag', num2str(index));
                    else
                        image = zeros(size(frames(:, :, index)));
                        image(:, :, 3) = frames(:, :, index);
                        image = hsv2rgb(image);
                        uiimage(ScrollPanel, "ScaleMethod",'scaledown', 'ImageSource', ...
                            labeloverlay(image, ones(size(frames(:, :, index))), 'Colormap', 'autumn'), "Position", [5, (5 + (i - 1)*(height/width*panelPos(4))), panelPos(3) - 10, height/width*(panelPos(4) - 10)], ...
                            "ImageClickedFcn", {@imageClicked},'Tooltip', "This frame will be ignored during bubble analysis", 'Tag', num2str(index));
                    end
                end
            end
            
            %Scroll to the top of the panel when done and show the first frame in the
            %main viewer
            scroll(ScrollPanel, 'top');
            
            imshow(frames(:, :, 1), 'Parent', mainAxes);
            hold(mainAxes, 'on');
            if ~app.IFFToggle.UserData
                startboundaries = cell2mat(bwboundaries(mask(:, :, 1)));
                plot(mainAxes, startboundaries(:, 2), startboundaries(:, 1), '-b', 'LineWidth', 2);
            end
            hold(mainAxes, 'off');

            frameInView = 1;
            
            %% Image Clicked Function
            function imageClicked(src, ~)
                frameNo = str2double(src.Tag);
                frameInView = frameNo;
                imshow(frames(:, :, frameInView), 'Parent', mainAxes);
                hold(mainAxes, 'on');
                if any(any(mask(:, :, frameInView)))
                    clickboundaries = cell2mat(bwboundaries(mask(:, :, frameInView)));
                    plot(mainAxes, clickboundaries(:, 2), clickboundaries(:, 1), '-b', 'LineWidth', 2);
                end
                hold(mainAxes, 'off');
            end
            
            %% Close Button Function
            function closeClicked(~, ~, MaskOverlayPreviewPanel)
                delete(MaskOverlayPreviewPanel);
            end
            
            %% Next Button Function
            function nextClicked(~, ~, topLim)
                if frameInView == topLim
                    frameInView = 1;
                    imshow(frames(:, :, frameInView), 'Parent', mainAxes);
                    hold(mainAxes, 'on');
                    nextboundaries = cell2mat(bwboundaries(mask(:, :, frameInView)));
                    plot(mainAxes, nextboundaries(:, 2), nextboundaries(:, 1), '-b', 'LineWidth', 2);
                    hold(mainAxes, 'off');
                else
                    frameInView = frameInView + 1;
                    imshow(frames(:, :, frameInView), 'Parent', mainAxes);
                    hold(mainAxes, 'on');
                    nextboundaries = cell2mat(bwboundaries(mask(:, :, frameInView)));
                    plot(mainAxes, nextboundaries(:, 2), nextboundaries(:, 1), '-b', 'LineWidth', 2);
                    hold(mainAxes, 'off');
                end
            end
            
            %% Previous Button Function
            function previousClicked(~, ~)
                if frameInView == 1
                    frameInView = app.numFrames;
                    imshow(frames(:, :, frameInView), 'Parent', mainAxes);
                    hold(mainAxes, 'on');
                    previousboundaries = cell2mat(bwboundaries(mask(:, :, frameInView)));
                    plot(mainAxes, previousboundaries(:, 2), previousboundaries(:, 1), '-b', 'LineWidth', 2);
                    hold(mainAxes, 'off');
                else
                    frameInView = frameInView - 1;
                    imshow(frames(:, :, frameInView), 'Parent', mainAxes);
                    hold(mainAxes, 'on');
                    previousboundaries = cell2mat(bwboundaries(mask(:, :, frameInView)));
                    plot(mainAxes, previousboundaries(:, 2), previousboundaries(:, 1), '-b', 'LineWidth', 2);
                    hold(mainAxes, 'off');
                end
            end
            
            %% Accept Button Function
            function acceptClicked(~, ~, app)
                app.ignoreFrames = app.ignoreFrames(app.ignoreFrames ~= frameInView);
                frameofInterest = findobj(ScrollPanel, 'Tag', num2str(frameInView));
                if any(any(app.mask(:, :, frameInView)))
                    frameofInterest.ImageSource = labeloverlay(app.frames(:, :, frameInView), app.mask(:, :, frameInView));
                else
                    plainimage = zeros(size(app.frames(:, :, frameInView)));
                    plainimage(:, :, 3) = app.frames(:, :, frameInView);
                    plainimage = hsv2rgb(plainimage);
                    frameofInterst.ImageSource = plainimage;
                end
                frameofInterst.Tooltip = "Click to ignore frame " + num2str(frameInView) + " during calculations";
                if app.FrameWarningToggle.UserData
                    uialert(app.UIFigure, 'This frame will be used during bubble analysis', 'Message', 'Icon', 'success');
                end
            end
            
            %% Reject Button Clicked
            function rejectClicked(~, ~, app)
                app.ignoreFrames(length(app.ignoreFrames) + 1) = frameInView;
                frameofInterest = findobj(ScrollPanel, 'Tag', num2str(frameInView));
                dontUseMask = ones(size(app.frames(:, :, frameInView)));
                frameofInterest.ImageSource = labeloverlay(app.frames(:, :, frameInView), dontUseMask, 'Colormap', 'autumn');
                frameofInterset.Tooltip = "This frame will be ignored during bubble analysis";
                if app.FrameWarningToggle.UserData
                    uialert(app.UIFigure, 'This frame will be ignored during bubble analysis', 'Message');
                end
            end
            
        end
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.currentFrame = 1;
            scroll(app.OverviewTab, 'top');
            checkVersion(app);
            figureSizeChange(app, 0);
        end
        
        function resetFunction(app)
            try
                % Clear main variables
                clear app.frames;
                clear app.mask;
                clear app.maskInformation;
                clear app.ignoreFrames;
                app.currentFrame = 1;
                clear app.radius;
                clear app.area;
                clear app.perimeter;
                clear app.surfaceArea;
                clear app.centroid;
                clear app.volume;
                clear app.velocity;
                clear app.numFrames;
                clear app.convertedPlotSet;
                
                %Clear plots and graphs
                cla(app.MainPlot);
                cla(app.EvolutionPlot);
                cla(app.RadiusPlot);
                yyaxis(app.TwoDimensionalPlot, 'left');
                cla(app.TwoDimensionalPlot);
                yyaxis(app.TwoDimensionalPlot, 'right');
                cla(app.TwoDimensionalPlot);
                yyaxis(app.ThreeDimensionalPlot, 'left');
                cla(app.ThreeDimensionalPlot);
                yyaxis(app.ThreeDimensionalPlot, 'right');
                cla(app.ThreeDimensionalPlot);
                cla(app.CentroidPlot);
                cla(app.VelocityPlot);
                yyaxis(app.AsphericityPlot, 'left');
                cla(app.AsphericityPlot);
                yyaxis(app.AsphericityPlot, 'right');
                cla(app.AsphericityPlot);
                
                %Reset Fourier Decomp Tab
                app.TargetFrameField.Value = 1;
                app.TermsofInterestField.Value = 8;
                delete(app.DecomposedPlotsPanel.Children);
            catch me
                uialert(app.UIFigure, me.message, append('Reset Error: ', me.identifier), 'Icon', 'error'); 
            end
        end
        
        function figureSizeChange(app, ~)
            try 
                f = uiprogressdlg(app.UIFigure, 'Message', 'Please wait...', 'Indeterminate', 'on');
                pause(0.5);
                position = app.UIFigure.Position;
                
                %Resize top level containers
                app.Toolstrip.Position = [0, position(4) - 55, position(3), 55];
                app.AnalysisTabs.Position = [1, 1, position(3)/2, position(4) - 55];
                app.ViewerTabs.Position  = [position(3)/2, 1, position(3)/2, position(4) - 55];
                drawnow;
                
                %Resize Toolbar
                parentPos = app.Toolstrip.Position;
                buttonsize = floor( (parentPos(3) - 1300 - 45)/9);
                offset = mod((parentPos(3) - 1300 - 45), 9);
                app.NewButton.Position = [offset, 5, buttonsize, 50];
                app.BatchButton.Position = [offset + buttonsize + 5, 5, buttonsize, 50];
                app.OpenButton.Position = [offset + 2*buttonsize + 10, 5, buttonsize, 50];
                app.SaveButton.Position = [offset + 3*buttonsize + 15, 5, buttonsize, 50];
                app.DetectButton.Position = [offset + 4*buttonsize + 20, 5, buttonsize, 50];
                app.MaskPreviewButton.Position = [offset + 5*buttonsize + 25, 5, buttonsize, 50];
                app.AnalyzeButton.Position = [offset + 6*buttonsize + 30, 5, buttonsize, 50];
                app.ExportButton.Position = [offset + 7*buttonsize + 35, 5, buttonsize, 50];
                app.IMRButton.Position = [offset + 8*buttonsize + 40, 5, buttonsize, 50];
                app.RotAxisLabel.Position = [parentPos(3) - 1300, 30, 100, 20];
                app.RotationAxis.Position = [parentPos(3) - 1195, 30, 90, 20];
                app.PreProcessLabel.Position = [parentPos(3) - 1300, 5, 100, 20];
                app.PreProcessMethod.Position = [parentPos(3) - 1195, 5, 90, 20];
                app.IFFToggleLabel.Position = [parentPos(3) - 1100, 30, 120, 20];
                app.IFFToggle.Position = [parentPos(3) - 975, 30, 40, 20];
                app.MultiToggleLabel.Position = [parentPos(3) - 1100, 5, 120, 20];
                app.MultiToggle.Position = [parentPos(3) - 975, 5, 40, 20];
                app.RDBWToggleLabel.Position = [parentPos(3) - 930, 30, 100, 20];
                app.RDBWToggle.Position = [parentPos(3) - 825, 30, 40, 20];
                app.FrameIgnoreLabel.Position = [parentPos(3) - 930, 5, 100, 20];
                app.FrameWarningToggle.Position = [parentPos(3) - 825, 5, 40, 20];
                app.FourierFitLabel.Position = [parentPos(3) - 780, 30, 160, 20];
                app.FourierFitToggle.Position = [parentPos(3) - 615, 30, 40, 20];
                pause(0.001);
                app.MinArcLengthLabel.Position = [parentPos(3) - 780, 5, 130, 20];
                app.MinArcLengthField.Position = [parentPos(3) - 645, 5, 70, 20];
                app.NumTermsLabel.Position = [parentPos(3) - 570, 30, 95, 20];
                app.NumTerms.Position = [parentPos(3) - 470, 30, 90, 20];
                app.FitTypeLabel.Position = [parentPos(3) - 570, 5, 50, 20];
                app.FitType.Position = [parentPos(3) - 515, 5, 135, 20];
                app.MaxTermsLabel.Position = [parentPos(3) - 375, 30, 100, 20];
                app.MaxTermsField.Position = [parentPos(3) -  270, 30, 55, 20];
                app.TermsofInterestLabel.Position = [parentPos(3) - 375, 5, 115, 20];
                app.TermsofInterestField.Position = [parentPos(3) -  255, 5, 40, 20];
                app.MicronPxLabel.Position = [parentPos(3) - 210, 30, 70, 20];
                app.MicronPxField.Position = [parentPos(3) - 135, 30, 40, 20];
                app.FPSLabel.Position = [parentPos(3) - 210, 7, 30 20];
                app.FPSField.Position = [parentPos(3) - 175, 5, 80, 20];
                app.PlotAxesLabel.Position = [parentPos(3) - 90, 30, 90, 20];
                app.PlotAxes.Position = [parentPos(3) - 90, 5, 90, 20];
                
                %Resize Analysis Tab Children
                parentPos = app.AnalysisTabs.Position;
                app.RadiusPlot.Position = [1, 5*3 + 3*parentPos(4)/3, parentPos(3) - 20, parentPos(4)/3];
                app.TwoDimensionalPlot.Position = [1, 5*2 + 2*parentPos(4)/3, parentPos(3) - 20, parentPos(4)/3];
                app.ThreeDimensionalPlot.Position = [1, 5 + parentPos(4)/3, parentPos(3) - 20, parentPos(4)/3];
                app.VelocityPlot.Position = [1, 1, parentPos(3) - 20, parentPos(4)/3];
                app.CentroidPlot.Position = [10 50 parentPos(3)-20 parentPos(4)-75];
                app.CentroidFirst.Position = [10, 5, 100, 40];
                app.CentroidLast.Position = [parentPos(3) - 100, 5, 90, 40];
                pause(0.001);
                parentPos = app.FourierFitDataTab.Position;
                app.AsphericityPlot.Position = [10, 50, parentPos(3) - 20, parentPos(4) - 60];
                app.FourierSecond.Position = [10, 5, 100, 40];
                app.FourierLast.Position = [parentPos(3) - 85, 5, 80, 40];
                %Redraw the colormap bar
                app.FourierColorMap.Position = [115, 5,parentPos(3) - 205, 40];
                position = app.FourierColorMap.Position;
                width = floor(position(3));
                height = floor(position(4));
                colorMapImage = zeros(height, width, 3);
                
                imageMap = viridis(width);
                
                redLine = transpose(imageMap(:, 1));
                greenLine = transpose(imageMap(:, 2));
                blueLine = transpose(imageMap(:, 3));
                
                redLayer = repmat(redLine, height, 1);
                greenLayer = repmat(greenLine, height, 1);
                blueLayer = repmat(blueLine, height, 1);
                
                colorMapImage(:, :, 1) = redLayer;
                colorMapImage(:, :, 2) = greenLayer;
                colorMapImage(:, :, 3) = blueLayer;
                app.FourierColorMap.ImageSource = colorMapImage;
                pause(0.001);
                parentPos = app.FourierDecompositionTab.Position;
                app.TargetFrameLabel.Position = [5, parentPos(4) - 27, 110, 22];
                app.TargetFrameField.Position = [120, parentPos(4) - 27, 58, 22];
                app.DecomposeButton.Position = [parentPos(3) - 105, parentPos(4) - 27, 100, 22];
                app.DecomposedPlotsPanel.Position = [1 1, parentPos(3), parentPos(4) - 50];
                drawnow;
                
                %Resize Viewer Children
                parentPos = app.ViewerTab.Position;
                app.PreviousFrameButton.Position = [5 5 55 55];
                app.NextFrameButton.Position = [parentPos(3) - 60, 5, 55, 55];
                app.JumpFrameLabel.Position = [floor(parentPos(3)/2 - 52.5), 5, 60, 20];
                app.JumpFrameField.Position = [floor(parentPos(3)/2 - 52.5) + 65, 5, 40, 20];
                app.FrameInspectorButton.Position = [floor(parentPos(3)/2 - 52.5), 30, 105, 20];
                app.MainPlot.Position = [5, 60, parentPos(3) - 10, parentPos(4) - 65];
                drawnow;
                
                %Resize Evolution Overlay Children
                parentPos = app.ViewerTabs.Position;
                app.EvolutionFirst.Position = [10, 5, 100, 40];
                app.EvolutionLast.Position = [parentPos(3) - 90, 5, 90, 40];
                app.EvolutionPlot.Position = [10, 50, parentPos(3) - 20, parentPos(4) - 80];
                drawnow;
                
                drawnow;
                pause(0.01);
                close(f);
            catch me
                uialert(app.UIFigure, me.message, append('Resize Error: ', me.identifier), 'Icon', 'error'); 
            end
        end
        
        function closeRequested(app, ~)
            delete(app);
        end
        
        function NewButtonPushed(app, ~)
            app.batchmode = false;
            try 
                resetFunction(app);
                f = uiprogressdlg(app.UIFigure, 'Title', "Please Wait", 'Message', "Loading video...", 'Indeterminate', 'on');
                app.frames = incaio.loadFrames();
                figure(app.UIFigure);
                [~, ~, app.numFrames] = size(app.frames);
                close(f);
                uialert(app.UIFigure, 'Video loaded!', 'Success', 'Icon',"success", "Modal", true);
                app.NewButton.BackgroundColor = [8 226 55]./255;
                app.NewButton.Tooltip = "Video loaded from source successfully";
            catch me
                uialert(app.UIFigure, me.message, append('File Open Error: ', me.identifier), 'Icon', 'error'); 
            end
        end
        
        function BatchButtonPushed(app, ~)
            selection = uiconfirm(app.UIFigure, 'Batch analysis will be conducted with current settings.', 'Continue?', 'Options', ...
                {'Continue with current settings', 'Cancel'}, 'DefaultOption', 1, 'CancelOption', 2);
            if all(selection == 'Continue with current settings')
                app.batchmode = true;
                [files, path] = uigetfile('*.avi', 'Select videos to analyze', 'MultiSelect', 'on');
                savepath = uigetdir();
                f = uiprogressdlg(app.UIFigure, 'Message', "Processing videos");
                for q = 1:length(files)
                    f.Value = q./length(files);
                    %% Set up the current file path
                    currentFilePath = append(path, files{q});
                    
                    %% Read the frames
                    vidObj = VideoReader(currentFilePath);
                    app.numFrames = vidObj.NumFrames;
                    vidObj = VideoReader(currentFilePath);
                    % Read the individual frames into a cell array
                    for j = 1:app.numFrames
                        pause(0.01);
                        img = readFrame(vidObj);            %Read the Frame
                        img = rgb2hsv(img);                 %Convert to HSV
                        img = img(:, :, 3);                 %Extract the value matrix
                        app.frames(:, :, j) = img;          %Store the frame in the cell array
                    end
                    
                    %% Run detection
                    DetectButtonPushed(app, 0);
                    
                    %% Run analysis
                    AnalyzeButtonPushed(app, 0);
                    
                    %% Save 
                    filename = append('BatchAnalysis', num2str(q));
                    fullsave = append(savepath, '\', filename, '.mat');
                    
                    frames = app.frames;
                    masks = app.mask;
                    infoStruct = app.maskInformation;
                    ignoreFrames = app.ignoreFrames;
                    BubbleRadius = app.radius;
                    BubbleArea = app.area;
                    BubblePerimeter = app.perimeter;
                    BubbleSurfaceArea = app.surfaceArea;
                    BubbleCentroid = app.centroid;
                    BubbleVolume = app.volume;
                    BubbleVelocity = app.velocity;
                    numFrames = app.numFrames;
                    alternatePlotSet = app.convertedPlotSet;
                    
                    save(fullsave, 'frames', 'masks', 'infoStruct', 'ignoreFrames', 'BubbleRadius', 'BubbleArea', 'BubblePerimeter', ...
                        'BubbleSurfaceArea', 'BubbleCentroid', 'BubbleVolume', 'BubbleVelocity', 'numFrames', 'alternatePlotSet', '-v7.3');
                end
                close(f);
                app.batchmode = false;
                uialert(app.UIFigure, 'Batch Processing Completed!', 'Success', 'Icon', "success", "Modal", true);
            end
        end
        
        function OpenButtonPushed(app, ~)
            w = uiprogressdlg(app.UIFigure, "Title", 'Please wait', 'Message', 'Loading data...', 'Indeterminate',"on");
            try 
                app = incaio.readFromFile(app);
            catch me
                uialert(app.UIFigure, me.message, append('Open Error: ', me.identifier), 'Icon', 'error');
            end
            figure(app.UIFigure);
            try
                plotting.displayCurrentFrame(app);
                
                sizes = zeros(1, app.numFrames);
                for i = 1:app.numFrames
                    sizes(i) = length(app.maskInformation(i).xData);
                end
                maxSize = max(sizes);
                if maxSize > 1
                    app.FourierFitToggle.UserData = 1;
                    app.FourierFitToggle.ImageSource = 'baseline_toggle_on_white_48dp.png';
                end
                
                if string(app.PlotAxes.Value) == "Px/Frame"
                    plotting.plotData(app.radius, app.area, app.perimeter, app.surfaceArea, app.volume, app.centroid, ...
                        app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot, app.numFrames, app.currentFrame);
                    plotting.dispEvolution(app);
                    plotting.plotFourier(app);
                else
                    plotting.plotConvertedData(app.convertedPlotSet, app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot,...
                        app.currentFrame, app.numFrames);
                    plotting.plotConvertedFourier(app);
                    plotting.dispEvolution(app);
                end
                drawnow;
            catch me
                uialert(app.UIFigure, me.message, append('Plotting Error: ', me.identifier), 'Icon', 'error'); 
            end
            pause(0.01);
            close(w);
        end
        
        function SaveButtonPushed(app, ~)
            try
                f = uiprogressdlg(app.UIFigure, "Title", "Please wait", 'Message', 'Saving...', "Indeterminate", "on");
                incaio.writeToFile(app);
                close(f);
            catch me
                uialert(app.UIFigure, me.message, append('Save Error: ', me.identifier), 'Icon', 'error'); 
            end
            uialert(app.UIFigure, "Save complete!", 'Message', 'Icon', "success");
        end
        
        function DetectButtonPushed(app, ~)
            %Clear any previous variables before running the bubble
            %detection
            clear app.ignoreFrames;
            clear app.mask;
            
            %If the use wishes to ignore the first frame then append it to
            %the vector of frames to ignore
            if app.IFFToggle.UserData == 1
                app.ignoreFrames(length(app.ignoreFrames) + 1) = 1;
            end
            
            %If the user wishes to pre process the frames then run the
            %frames through the preprocessing function, otherwise just
            %assign the frames to be inspected to the original frames
            try 
                if string(app.PreProcessMethod.Value) ~= "None"
                    detectionFrames = bubbleAnalysis.preprocessFrames(app, app.frames);
                else
                    detectionFrames = app.frames;
                end
            catch ME
                uialert(app.UIFigure, ME.message, append('Preprocessing Error: ', ME.identifier), 'Icon', 'error'); 
            end
            
            try 
                if app.MultiToggle.UserData == 1
                    app.mask = bubbleAnalysis.multiViewDetect(detectionFrames);
                else
                    %If the user wants to run the detection on the frames both ways
                    %then run it forwards, then reverse, and then compare the two.
                    %Otherwise just run the detection forward
                    if app.RDBWToggle.UserData == 1
                        forwardMask = bubbleAnalysis.maskGen(app.UIFigure, detectionFrames, 'forward', app.IgnoreFirstFrameCheckBox.Value);
                        reverseMask = bubbleAnalysis.maskGen(app.UIFigure, detectionFrames, 'reverse', app.IgnoreFirstFrameCheckBox.Value);
                        f = uiprogressdlg(app.UIFigure ,"Title", "Please wait", "Message", "Comparing masks...", "Indeterminate","on");
                        app.mask = bubbleAnalysis.compareMasks(forwardMask, reverseMask);
                        close(f)
                    else
                        app.mask = bubbleAnalysis.maskGen(app.UIFigure, detectionFrames, 'forward', app.IFFToggle.UserData);
                    end
                end
            catch me
               uialert(app.UIFigure, me.message, append('Detection Error: ', me.identifier), 'Icon', 'error'); 
            end
            
            if ~app.batchmode
                %User niceties
                f = uiprogressdlg(app.UIFigure ,"Title", "Please wait", "Message", "Generating frame previews...", "Indeterminate","on");
                generatePreviews(app, app.frames, app.mask);
                close(f);
                uialert(app.UIFigure, "Bubble detection complete! Please review frames before proceeding.", 'Message', 'Icon', 'info');
            end
        end
        
        function MaskPreviewButtonPushed(app, ~)
            try
                generatePreviews(app, app.frames, app.mask);
            catch ME
                uialert(app.UIFigure, ME.message, append('Display Error: ', ME.identifier), 'Icon', 'error'); 
            end
        end
        
        function AnalyzeButtonPushed(app, ~)
            clear app.maskInformation
            if string(app.NumTerms.Value) == "Fixed"
                adaptiveTerms = 0;
            else 
                adaptiveTerms = 1;
            end
            try 
                app.maskInformation = bubbleAnalysis.bubbleTrack(app, app.mask, app.MinArcLengthField.Value, lower(string(app.RotationAxis.Value)),...
                    app.FourierFitToggle.UserData, app.MaxTermsField.Value, adaptiveTerms, app.ignoreFrames, lower(string(app.FitType.Value)));
            catch ME
                uialert(app.UIFigure, ME.message, append('Analysis Error: ', ME.identifier), 'Icon', 'error'); 
            end
            [app.radius, app.area, app.perimeter, app.surfaceArea, app.volume, app.centroid, app.velocity] = plotting.generatePlotData(app);
            app.convertedPlotSet = plotting.convertUnits(app);
            if ~app.batchmode
                f = uiprogressdlg(app.UIFigure ,"Title", "Please wait", "Message", "Configuring for plotting...", "Indeterminate","on");
                try
                    plotting.displayCurrentFrame(app);
                    if string(app.PlotAxes.Value) == "Px/Frame"
                        plotting.plotData(app.radius, app.area, app.perimeter, app.surfaceArea, app.volume, app.centroid, ...
                            app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot, app.numFrames, app.currentFrame);
                        plotting.dispEvolution(app);
                        plotting.plotFourier(app);
                        plotting.plotVelocity(app.VelocityPlot, app.velocity);
                    else
                        plotting.plotConvertedData(app.convertedPlotSet, app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot,...
                            app.currentFrame, app.numFrames);
                        plotting.plotConvertedFourier(app);
                        plotting.dispEvolution(app);
                    end
                catch ME
                    uialert(app.UIFigure, ME.message, append('Plotting Error: ', ME.identifier), 'Icon', 'error');
                end
                drawnow;
                pause(0.01);
                close(f);
            end
        end
        
        function ExportButtonPushed(app, ~)
            try
                incaio.exportToExcel(app, app.ignoreFrames);
            catch ME
                uialert(app.UIFigure, ME.message, append('Export Error: ', ME.identifier), 'Icon', 'error'); 
            end
            uialert(app.UIFigure, "Export complete!", 'Message', 'Icon', "success");
        end

        function IMRButtonPushed(app, ~)
            try
                data = incaio.configureDataForIMR(app.frames, app.mask, app.numFrames, app.ignoreFrames, ...
                    app.maskInformation, app.convertedPlotSet, app.TermsofInterestField.Value, lower(string(app.FitType.Value)));
                [file, path] = uiputfile('*.mat');
                savePath = append(path, file);
                save(savePath, 'data', '-v7.3');
            catch me
                uialert(app.UIFigure, me.message, append('Data Configuration Error: ', me.identifier), 'Icon', 'error'); 
            end
        end
        
        function PreviousButtonPushed(app, ~)
            if app.currentFrame == 1
                app.currentFrame = app.numFrames;
            else
                app.currentFrame = app.currentFrame - 1;
            end
            plotting.displayCurrentFrame(app);
            if string(app.PlotAxes.Value) == "Px/Frame"
                plotting.plotData(app.radius, app.area, app.perimeter, app.surfaceArea, app.volume, app.centroid, ...
                    app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot, app.numFrames, app.currentFrame);
            else
                plotting.plotConvertedData(app.convertedPlotSet, app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot,...
                    app.currentFrame, app.numFrames);
            end
            app.JumpFrameField.Value = app.currentFrame;
        end
        
        function NextButtonPushed(app, ~)
            if app.currentFrame == app.numFrames
                app.currentFrame = 1;
            else
                app.currentFrame = app.currentFrame + 1;
            end
            plotting.displayCurrentFrame(app);
            if string(app.PlotAxes.Value) == "Px/Frame"
                plotting.plotData(app.radius, app.area, app.perimeter, app.surfaceArea, app.volume, app.centroid, ...
                    app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot, app.numFrames, app.currentFrame);
            else
                plotting.plotConvertedData(app.convertedPlotSet, app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot,...
                    app.currentFrame, app.numFrames);
            end
            app.JumpFrameField.Value = app.currentFrame;
        end
        
        function DecomposeButtonPushed(app, ~)
            delete(app.DecomposedPlotsPanel.Children);
            try 
                f = uiprogressdlg(app.UIFigure ,"Title", "Please wait", "Message", "Decomposing", "Indeterminate","on");
                decompPlots = plotting.fourierDecomposition(app.maskInformation, app.TargetFrameField.Value, app.TermsofInterestField.Value, "descending", ...
                    lower(string(app.FitType.Value)));
                f.Title = "Plotting...";
                plotting.plotFourierDecomp(app, decompPlots);
                close(f);
            catch me
                uialert(app.UIFigure, me.message, append('Decomposition Error: ', me.identifier), 'Icon', 'error'); 
            end
        end
        
        function JumpFrameFieldValueChanged(app, ~)
            value = app.JumpFrameField.Value;
            app.currentFrame = value;
            plotting.displayCurrentFrame(app);
            if string(app.PlotAxes.Value) == "Px/Frame"
                plotting.plotData(app.radius, app.area, app.perimeter, app.surfaceArea, app.volume, app.centroid, ...
                    app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot, app.numFrames, app.currentFrame);
            else
                plotting.plotConvertedData(app.convertedPlotSet, app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot,...
                    app.currentFrame, app.numFrames);
            end
        end
        
        function RotAxisChange(app, ~)
            selection = uiconfirm(app.UIFigure, 'Changing the rotational axis will require that surface area and of the bubbles are recomputed. Do you want to continue?', ...
                'Confirm change?', 'Icon', 'warning', 'Options', {'Yes', 'No'}, "DefaultOption", 1, 'CancelOption', 2);
            if selection == 'Yes'
                app.maskInformation = bubbleAnalysis.reCalcSurfandVolume(app.maskInformation, lower(app.RotationAxis.Value), app.numFrames, app.ignoreFrames);
            end
        end
        
        function PlotAxisChange(app, ~)
            f = uiprogressdlg(app.UIFigure ,"Title", "Please wait", "Message", "Converting...", "Indeterminate","on");
            app.convertedPlotSet = plotting.convertUnits(app);
            if string(app.PlotAxes.Value) == "Px/Frame"
                plotting.plotData(app.radius, app.area, app.perimeter, app.surfaceArea, app.volume, app.centroid, ...
                    app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot, app.numFrames, app.currentFrame);
                plotting.plotFourier(app);
                plotting.changeAxesTitles(app, 'pixels');
            else
                plotting.plotConvertedData(app.convertedPlotSet, app.RadiusPlot, app.TwoDimensionalPlot, app.ThreeDimensionalPlot, app.CentroidPlot,...
                    app.currentFrame, app.numFrames);
                plotting.plotConvertedFourier(app);
                plotting.changeAxesTitles(app, 'microns');
            end
            close(f);
        end
        
        function FrameInspectorButtonPushed(app, ~)
            try
                info.PerimeterPoints = app.maskInformation(app.currentFrame).PerimeterPoints;
                info.Centroid = app.maskInformation(app.currentFrame).Centroid;
                info.TrackingPoints = app.maskInformation(app.currentFrame).TrackingPoints;
                info.FourierPoints = app.maskInformation(app.currentFrame).FourierPoints;
                if iscell(app.maskInformation(app.currentFrame).perimEq)
                    xFunc = app.maskInformation(app.currentFrame).perimEq{1};
                    yFunc = app.maskInformation(app.currentFrame).perimEq{2};
                    info.xData = xFunc(linspace(1, length(app.maskInformation(app.currentFrame).FourierPoints(:, 1)), ...
                        numcoeffs(app.maskInformation(app.currentFrame).perimFit{1}).*25));
                    info.yData = yFunc(linspace(1, length(app.maskInformation(app.currentFrame).FourierPoints(:, 2)), ...
                        numcoeffs(app.maskInformation(app.currentFrame).perimFit{2}).*25));
                else
                    rFunc = app.maskInformation(app.currentFrame).perimEq;
                    rData = rFunc(linspace(0, 2*pi, 1000));
                    [xraw, yraw] = pol2cart(linspace(0, 2*pi, 1000), rData);
                    info.xData = xraw + app.maskInformation(app.currentFrame).Centroid(1);
                    info.yData = yraw + app.maskInformation(app.currentFrame).Centroid(2);
                end
                orientation = app.maskInformation(app.currentFrame).Orientation;
                frameInspector(app.frames(:, :, app.currentFrame), app.mask(:, :, app.currentFrame), info, app.FourierFitToggle.UserData, 5, ...
                    orientation);
            catch me
                uialert(app.UIFigure, me.message, append('Frame Inspection Display Error: ', me.identifier), 'Icon', 'error'); 
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)
            
            %Set up 
            addpath('main');
            addpath('icons');
            addpath('fonts');
            buttonsize = 50;

            %Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off', 'Position', [1, 41, 1920, 1017], 'WindowState', 'normal', ...
                'AutoResizeChildren', 'off', 'Name', 'InCA', 'Scrollable', 'on', 'Color', [0 0 0]);
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @figureSizeChange, true);
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeRequested, true);
            
            %Create the toolstrip object
            parentPos = app.UIFigure.Position;
            app.Toolstrip = uipanel('Parent', app.UIFigure, 'BorderType', 'none', 'Position', [0, parentPos(4) - 55, parentPos(3), 55], ...
            'BackgroundColor', [0 0 0], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
        
            %% Populate the toolstrip 
            %Buttons
            app.NewButton = uibutton(app.Toolstrip, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'baseline_add_white_48dp.png', 'IconAlignment', 'top', 'Text', 'NEW', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [5, 5, buttonsize, buttonsize], 'BackgroundColor', [0, 0.29, 1], 'Tooltip', 'Load a new video for analysis');
            app.NewButton.ButtonPushedFcn = createCallbackFcn(app, @NewButtonPushed, true);
            app.BatchButton = uibutton(app.Toolstrip, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'baseline_dynamic_feed_white_48dp.png', 'IconAlignment', 'top', 'Text', 'BATCH', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [60, 5, buttonsize, buttonsize], 'BackgroundColor', [0, 0.29, 1], 'Tooltip', 'Load multiple videos for sequential analysis');
            app.BatchButton.ButtonPushedFcn = createCallbackFcn(app, @BatchButtonPushed, true);
            app.OpenButton = uibutton(app.Toolstrip, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'baseline_folder_open_white_48dp.png', 'IconAlignment', 'top', 'Text', 'OPEN', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [115, 5, buttonsize, buttonsize], 'BackgroundColor', [0, 0.29, 1], 'Tooltip', 'Open a previously analyzed video');
            app.OpenButton.ButtonPushedFcn = createCallbackFcn(app, @OpenButtonPushed, true);
            app.SaveButton = uibutton(app.Toolstrip, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'baseline_save_white_48dp.png', 'IconAlignment', 'top', 'Text', 'SAVE', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [170, 5, buttonsize, buttonsize], 'BackgroundColor', [0, 0.29, 1], 'Tooltip', 'Save current analysis to file');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.DetectButton = uibutton(app.Toolstrip, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'baseline_search_white_48dp.png', 'IconAlignment', 'top','Text', 'DETECT', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [225, 5, buttonsize, buttonsize], 'BackgroundColor', [0, 0.29, 1], 'Tooltip', 'Attempt to isolate bubble with current detection settings');
            app.DetectButton.ButtonPushedFcn = createCallbackFcn(app, @DetectButtonPushed, true);
            app.MaskPreviewButton = uibutton(app.Toolstrip, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'baseline_preview_white_48dp.png', 'IconAlignment', 'top', 'Text', 'MASKS', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [280, 5, buttonsize, buttonsize], 'BackgroundColor', [0, 0.29, 1], 'Tooltip', 'View the overlay of the detected mask on the original image');
            app.MaskPreviewButton.ButtonPushedFcn = createCallbackFcn(app, @MaskPreviewButtonPushed, true);
            app.AnalyzeButton = uibutton(app.Toolstrip, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'baseline_polymer_white_48dp.png', 'IconAlignment', 'top', 'Text', 'ANALYZE', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [335, 5, buttonsize, buttonsize], 'BackgroundColor', [0, 0.29, 1], 'HorizontalAlignment', 'center', 'Tooltip', 'Analyze the detected bubble masks to gather kinematic bubble information');
            app.AnalyzeButton.ButtonPushedFcn = createCallbackFcn(app, @AnalyzeButtonPushed, true);
            app.ExportButton = uibutton(app.Toolstrip, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'excel.png', 'IconAlignment', 'top', 'Text', 'EXPORT', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [390, 5, buttonsize, buttonsize], 'BackgroundColor', [0, 0.29, 1], 'Tooltip', 'Export the analysis data to a Microsoft Excel file');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.IMRButton = uibutton(app.Toolstrip, 'push', 'FontName', 'Roboto Medium', 'FontSize', 10, ...
                'Icon', 'baseline_open_in_new_white_48dp.png', 'IconAlignment', 'top', 'Text', 'TO IMR', 'VerticalAlignment', 'bottom', 'FontColor', [1 1 1], ...
                'Position', [445, 5, buttonsize, buttonsize], 'BackgroundColor', [0, 0.29, 1], 'Tooltip', 'Configure and save the analysis data for use with IMR');
            app.IMRButton.ButtonPushedFcn = createCallbackFcn(app, @IMRButtonPushed, true);
            
            %Detection Settings
            app.RotAxisLabel = uilabel(app.Toolstrip, 'Text', 'ROTATION AXIS', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [500, 30, 100, 20], 'Tooltip', 'Select which axis the perimeter points should be rotated around to calculate 3D properties');
            app.RotationAxis = uidropdown(app.Toolstrip, 'Items', {'Major', 'Minor', 'Horizontal', 'Vertical'}, 'Value', 'Major', 'FontName', 'Roboto Medium', ...
                'FontColor', [1, 1 ,1], 'BackgroundColor', [0 0 0], 'Position', [605, 30, 90, 20], 'Tooltip', 'Select which axis the perimeter points should be rotated around to calculate 3D properties');
            app.RotationAxis.ValueChangedFcn = createCallbackFcn(app, @RotAxisChange, true);
            app.PreProcessLabel = uilabel(app.Toolstrip, 'Text', 'PREPROCESSING', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [500, 5, 100, 20], 'Tooltip', 'Preprocess the frames for increased detection accuracy');
            app.PreProcessMethod = uidropdown(app.Toolstrip, 'Items', {'None', 'Sharpen', 'Soften'}, 'Value', 'Sharpen', 'FontName', 'Roboto Medium', ...
                'FontColor', [1, 1 ,1], 'BackgroundColor', [0 0 0], 'Position', [605, 5, 90, 20], 'Tooltip', 'Preprocess the frames for increased detection accuracy');
            app.IFFToggleLabel = uilabel(app.Toolstrip, 'Text', 'IGNORE FIRST FRAME', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [700, 30, 120, 20], 'Tooltip', 'Ignore the first frame of the video (common with high speed cameras)');
            app.IFFToggle = uiimage(app.Toolstrip, 'ImageSource', 'baseline_toggle_on_white_48dp.png', 'Position', [825, 30, 40, 20], ...
                'ScaleMethod', 'fit', 'UserData', 1, 'ImageClickedFcn', {@toggleClicked}, 'Tooltip', 'Ignore the first frame of the video (common with high speed cameras)');
            app.MultiToggleLabel = uilabel(app.Toolstrip, 'Text', '      MULTI-VIEWPOINT', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [700, 5, 120, 20], 'Tooltip', 'Tells InCA to expect multiple (possibly overlapping) bubbles per frame');
            app.MultiToggle = uiimage(app.Toolstrip, 'ImageSource', 'baseline_toggle_off_white_48dp.png', 'Position', [825, 5, 40, 20], ...
                'ScaleMethod', 'fit', 'UserData', 0, 'ImageClickedFcn', {@toggleClicked},  'Tooltip', 'Tells InCA to expect multiple (possibly overlapping) bubbles per frame');
            app.RDBWToggleLabel = uilabel(app.Toolstrip, 'Text', 'DUAL DETECTION', 'FontName', 'Roboto Medium', 'FontColor', [1 1 1], ...
                'Position', [870, 30, 100, 20], 'Tooltip', 'Run the detection algorithm both forwards and backwards in time for increased accuracy');
            app.RDBWToggle = uiimage(app.Toolstrip, 'ImageSource', 'baseline_toggle_off_white_48dp.png', 'Position', [975, 30, 40, 20], ...
                'ScaleMethod', 'fit', 'UserData', 0,'ImageClickedFcn', {@toggleClicked}, 'Tooltip', 'Run the detection algorithm both forwards and backwards in time for increased accuracy');
            app.FrameIgnoreLabel = uilabel(app.Toolstrip, 'Text', 'IGNORE WARNING', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [870, 5, 100, 20], 'Tooltip', 'Toggle the warning alert when selecting frames to ignore in the mask preview window');
            app.FrameWarningToggle = uiimage(app.Toolstrip, 'ImageSource', 'baseline_toggle_on_white_48dp.png', 'Position', [975, 5, 40, 20], ...
                'ScaleMethod', 'fit', 'UserData', 1 ,'ImageClickedFcn', {@toggleClicked}, 'Tooltip', 'Toggle the warning alert when selecting frames to ignore in the mask preview window');
            
            %Analysis Settings
            app.FourierFitLabel = uilabel(app.Toolstrip, 'Text', 'FOURIER RECONSTRUCTION', 'FontName', 'Roboto Medium', 'FontColor', [1, 1,1], ...
                'Position', [1020, 30, 160, 20], 'Tooltip', 'Tells InCA whether or not to fit a Fourier series to the perimeter of the bubble');
            app.FourierFitToggle = uiimage(app.Toolstrip, 'ImageSource', 'baseline_toggle_off_white_48dp.png', 'Position', [1185, 30, 40, 20], ...
                'ScaleMethod', 'fit', 'UserData', 0, 'ImageClickedFcn', {@toggleClicked}, 'Tooltip', 'Tells InCA whether or not to fit a Fourier series to the perimeter of the bubble');
            app.MinArcLengthLabel = uilabel(app.Toolstrip, 'Text', 'MINIMUM ARC LENGTH', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [1020, 5, 130, 20], 'Tooltip', 'The minimum arc length between points to be considered for the Fourier Perimeter fit');
            app.MinArcLengthField = uieditfield(app.Toolstrip, 'numeric', 'BackgroundColor', [0, 0, 0], 'FontName', 'Roboto Medium', 'Value', 3, 'FontColor', ...
                [1, 1, 1], 'Position', [1155, 5, 70, 20], 'Limits', [0, Inf], 'Tooltip', 'The minimum arc length between points to be considered for the Fourier Perimeter fit');
            app.NumTermsLabel = uilabel(app.Toolstrip, 'Text', 'NUMBER TERMS', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [1230, 30, 95, 20], 'Tooltip', 'Tells InCA whether or not to use a dynamic number of terms in the fit depending on Nyquist sampling rules for how many points there are on the perimeter');
            app.NumTerms = uidropdown(app.Toolstrip, 'Items', {'Fixed', 'Variable'}, 'Value', 'Fixed', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [1330, 30, 90, 20], 'BackgroundColor', [0, 0, 0], 'Tooltip', 'Tells InCA whether or not to use a dynamic number of terms in the fit depending on Nyquist sampling rules for how many points there are on the perimeter');
            app.FitTypeLabel = uilabel(app.Toolstrip, 'Text', 'FIT TYPE', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [1230, 5, 50, 20], 'Tooltip', 'Tells InCA which type of function to construct to fit the perimeter points to');
            app.FitType = uidropdown(app.Toolstrip, 'Items', {'Parametric', 'Polar (Standard)', 'Polar (Phase Shift)'}, 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'BackgroundColor', [0 0 0], 'Position', [1285, 5, 135, 20], 'Value', 'Polar (Standard)', 'Tooltip', 'Tells InCA which type of function to construct to fit the perimeter points to');
            app.MaxTermsLabel = uilabel(app.Toolstrip, 'Text', 'MAX NUM TERMS', 'FontName', 'Roboto Medium', 'FontColor', [1 1 1], 'Position', [1425, 30, 100, 20], ...
                'Tooltip', 'The maximum number of terms InCA should use in the fit');
            app.MaxTermsField = uieditfield(app.Toolstrip, 'numeric', 'Value', 40, 'Limits', [1, Inf], 'FontName', 'Roboto Medium', 'FontColor', [1 1 1], ...
                'BackgroundColor', [0 0 0], 'Position', [1530, 30, 55, 20], 'Tooltip', 'The maximum number of terms InCA should use in the fit');
            app.TermsofInterestLabel = uilabel(app.Toolstrip, 'Text', 'TERMS OF INTEREST', 'FontName', 'Roboto Medium', 'FontColor', [1 1 1], 'Position', ...
                [1425, 5, 115, 20], 'Tooltip', 'The number of terms to be used for asphericity, decomposition, and export');
            app.TermsofInterestField = uieditfield(app.Toolstrip, 'numeric', 'Value', 8, 'Limits', [1, Inf], 'FontName', 'Roboto Medium', 'FontColor', [1 1 1], ...
                'BackgroundColor', [0 0 0], 'Position', [1545, 5, 40, 20], 'Tooltip', 'The number of terms to be used for asphericity, decomposition, and export');
            
            %Camera Settings
            app.MicronPxLabel = uilabel(app.Toolstrip, 'Text', 'MICRON/PX', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], 'Position', [1590, 30, 70, 20]);
            app.MicronPxField = uieditfield(app.Toolstrip, 'numeric', 'Value', 0, 'FontColor', [1 1 1], 'BackgroundColor', [0 0 0], 'FontName', 'Roboto Medium',...
                'Position', [1665, 30, 40, 20]);
            app.FPSLabel = uilabel(app.Toolstrip, 'Text', 'FPS', 'FontName', 'Roboto Medium', 'FontColor', [1 1 1], 'Position', [1590, 7, 30 20]);
            app.FPSField = uieditfield(app.Toolstrip, 'numeric', 'Value', 0, 'FontColor', [1 1 1], 'BackgroundColor', [0 0 0], 'FontName', 'Roboto Medium',...
                'Position', [1625, 5, 80, 20]);
            app.PlotAxesLabel = uilabel(app.Toolstrip, 'Text', 'PLOT AXES', 'FontName', 'Roboto Medium', 'FontColor', [1 1 1], 'Position', ...
                [1710, 30, 90, 20], 'HorizontalAlignment', 'center');
            app.PlotAxes = uidropdown(app.Toolstrip, 'Items', {'Px/Frame', 'Micron/s'}, 'Value', 'Px/Frame', 'FontName', 'Roboto Medium', 'FontColor', [1, 1, 1], ...
                'Position', [1710, 5, 90, 20], 'BackgroundColor', [0, 0, 0]);
            app.PlotAxes.ValueChangedFcn = createCallbackFcn(app, @PlotAxisChange, true);
            
            %% Create the analysis tab group
            app.AnalysisTabs = uitabgroup(app.UIFigure, 'Position', [1, 1, 900, 744], 'AutoResizeChildren', 'off');
            parentPos = app.AnalysisTabs.Position;
                        
            %Create the tabs
            app.OverviewTab = uitab(app.AnalysisTabs, 'Title', 'Overview', 'BackgroundColor', [0, 0, 0], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
            app.CentroidTab = uitab(app.AnalysisTabs, 'Title', 'Centroid', 'BackgroundColor', [0, 0, 0], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
            app.FourierFitDataTab = uitab(app.AnalysisTabs, 'Title', 'Fourier Fit Data', 'BackgroundColor', [0, 0, 0], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
            app.FourierDecompositionTab = uitab(app.AnalysisTabs, 'Title', 'Fourier Decomposition', 'BackgroundColor', [0, 0, 0], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
            app.SphericalHarmonicsTab = uitab(app.AnalysisTabs, 'Title', 'Spherical Harmonics', 'BackgroundColor', [0 0 0], 'Scrollable', 'on', 'AutoResizeChildren', 'off');
            
            %Populate the Overview Tab
            app.VelocityPlot = uiaxes(app.OverviewTab, 'AmbientLightColor', [0 0 0], 'FontName', 'Roboto', 'FontSize', 12, 'XColor', [1 1 1], ...
                'YColor', [1 1 1], 'Color', [0 0 0], 'BackgroundColor', [0 0 0], 'Position', [1, 1, parentPos(3) - 20, parentPos(4)/3]);
            title(app.VelocityPlot, "PERIMETER VELOCITY (PX/FRAME)", 'Color', [1 1 1]);
            xlabel(app.VelocityPlot, "FRAME");
            ylabel(app.VelocityPlot, "VELOCITY");
            
            app.ThreeDimensionalPlot = uiaxes(app.OverviewTab, 'AmbientLightColor', [0 0 0], 'FontName', 'Roboto', 'FontSize', 12, 'XColor', [1 1 1], ...
                'YColor', [183 0 255]./255, 'Color', [0 0 0], 'BackgroundColor', [0 0 0], 'Position', [1, 5 + parentPos(4)/3, parentPos(3) - 20, parentPos(4)/3], ...
                'ColorOrder', [0.7176 0 1; 1 0 0.2824]);
            title(app.ThreeDimensionalPlot, "SURFACE AREA AND VOLUME (PX/FRAME)", 'Color', [1 1 1]);
            xlabel(app.ThreeDimensionalPlot, "FRAME");
            ylabel(app.ThreeDimensionalPlot, "SURFACE AREA");
            yyaxis(app.ThreeDimensionalPlot, 'right');
            ylabel(app.ThreeDimensionalPlot, "VOLUME");
            app.ThreeDimensionalPlot.YColor = [255 0 72]./255;
            yyaxis(app.ThreeDimensionalPlot, 'left');
            app.ThreeDimensionalPlot.YColor = [183 0 255]./255;
            
            app.TwoDimensionalPlot = uiaxes(app.OverviewTab, 'AmbientLightColor', [0 0 0], 'FontName', 'Roboto', 'FontSize', 12, 'XColor', [1 1 1], ...
                'YColor', [183 0 255]./255, 'Color', [0 0 0], 'BackgroundColor', [0 0 0], 'Position', [1, 5*2 + 2*parentPos(4)/3, parentPos(3) - 20, parentPos(4)/3], ...
                'ColorOrder', [0.7176 0 1; 1 0 0.2824]);
            title(app.TwoDimensionalPlot, "AREA AND PERIMETER (PX/FRAME)", 'Color', [1 1 1]);
            xlabel(app.TwoDimensionalPlot, "FRAME");
            ylabel(app.TwoDimensionalPlot, "AREA");
            yyaxis(app.TwoDimensionalPlot, 'right');
            ylabel(app.TwoDimensionalPlot, "PERIMETER");
            app.TwoDimensionalPlot.YColor = [255 0 72]./255;
            yyaxis(app.TwoDimensionalPlot, 'left');
            app.TwoDimensionalPlot.YColor = [183 0 255]./255;
            
            app.RadiusPlot = uiaxes(app.OverviewTab, 'AmbientLightColor', [0 0 0], 'FontName', 'Roboto', 'FontSize', 12, 'XColor', [1 1 1], ...
                'YColor', [1 1 1], 'Color', [0 0 0], 'BackgroundColor', [0 0 0], 'Position', [1, 5*3 + 3*parentPos(4)/3, parentPos(3) - 20, parentPos(4)/3]);
            title(app.RadiusPlot, "AVERAGE RADIUS(PX/FRAME)", 'Color', [1 1 1]);
            xlabel(app.RadiusPlot, "FRAME");
            ylabel(app.RadiusPlot, "RADIUS");
            
            %Populate the centroid tab
            app.CentroidPlot = uiaxes(app.CentroidTab, 'AmbientLightColor', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'Color', [0 0 0], ...
                'BackgroundColor', [0 0 0], 'Position', [10 50 parentPos(3)-10 parentPos(4)-75], 'Box', 'on', 'FontName', 'Roboto');
            title(app.CentroidPlot, "CENTROID COORDINATES", 'Color', [1 1 1]);
            app.CentroidFirst = uilabel(app.CentroidTab, 'Text', 'FIRST FRAME', 'FontColor', [178, 24, 43]./255, 'FontName', 'Roboto Medium', ...
                'FontSize', 14, 'Position', [10, 5, 100, 40]);
            app.CentroidLast = uilabel(app.CentroidTab, 'Text', 'LAST FRAME', 'FontColor', [33, 102, 172]./255, 'FontName', 'Roboto Medium', ...
                'FontSize', 14, 'Position', [800, 5, 100, 40]);
            
            %Populate the Fourier Fit Tab
            app.AsphericityPlot = uiaxes(app.FourierFitDataTab', 'AmbientLightColor', [1 1 1], 'XColor', [1 1 1], 'Color', [0 0 0], ...
                'BackgroundColor', [0 0 0], 'Position', [10, 50, app.FourierFitDataTab.Position(3) - 20, app.FourierFitDataTab.Position(4) - 10], ...
                'FontName', 'Roboto');
            title(app.AsphericityPlot, "RELATIVE ASPHERICITY", 'Color', [1 1 1]);
            xlabel(app.AsphericityPlot, "FRAME");
            yyaxis(app.AsphericityPlot, 'right');
            ylabel(app.AsphericityPlot, "NORMALIZED RADIUS", 'Color', [1 1 1]);
            app.AsphericityPlot.YColor = [1 1 1];
            yyaxis(app.AsphericityPlot, 'left');
            ylabel(app.AsphericityPlot, "sqrt(aN^2 + bN^2) / sqrt(a1^2 + b1^2)");
            cmap = viridis(64);
            app.AsphericityPlot.YColor = cmap(end, :);
            app.FourierSecond = uilabel(app.FourierFitDataTab, 'Text', 'SECOND TERM', 'FontColor', [1 1 1], 'FontName', 'Roboto Medium', ...
                'FontSize', 14, 'Position', [10, 5, 100, 40]);
            app.FourierLast = uilabel(app.FourierFitDataTab, 'Text', 'LAST TERM', 'FontColor', [1 1 1], 'FontName', 'Roboto Medium', ...
                'FontSize', 14, 'Position', [815, 5, 80, 40]);
            app.FourierColorMap = uiimage(app.FourierFitDataTab, 'Position', [115, 5, 695, 40]);
            
            %Populate the Fourier Decomp Tab
            parentPos = app.FourierDecompositionTab.Position;
            app.TargetFrameLabel = uilabel('Parent', app.FourierDecompositionTab, 'FontName', 'Roboto', 'FontSize', 14, 'Text', ...
                'TARGET FRAME', 'FontColor', [1 1 1], 'Position', [10, parentPos(4) - 27, 82, 22]);
            app.TargetFrameField = uieditfield(app.FourierDecompositionTab, 'numeric', 'Value', 1, 'FontColor', [1 1 1], 'BackgroundColor', [0 0 0], 'FontName', 'Roboto Medium',...
                'Position', [97, parentPos(4) - 27, 58, 22]);
            app.DecomposeButton = uibutton(app.FourierDecompositionTab, 'push', 'FontName', 'Roboto Medium', 'FontSize', 12, ...
                'Text', 'DECOMPOSE', 'FontColor', [1 1 1], 'Position', [parentPos(3) - 105, parentPos(4) - 27, 100, 22], 'BackgroundColor', [0, 0.29, 1]);
            app.DecomposeButton.ButtonPushedFcn = createCallbackFcn(app, @DecomposeButtonPushed, true);
            app.DecomposedPlotsPanel = uipanel('Parent', app.FourierDecompositionTab, 'BorderType', 'none', 'Position', [1, 1, parentPos(3), parentPos(4) - 68], ...
            'BackgroundColor', [0 0 0], 'Scrollable', 'on', 'AutoResizeChildren', 'off', 'title', 'DECOMPOSED PLOTS', 'FontName', 'Roboto Medium', 'FontSize', ...
            14, 'ForegroundColor', [1 1 1], 'TitlePosition', 'centertop');
        
            %% Create the viewer tab group
            app.ViewerTabs = uitabgroup(app.UIFigure, 'Position', [900, 1, 900, 744], 'AutoResizeChildren', 'off');
            
            %Create the tabs
            app.ViewerTab = uitab(app.ViewerTabs, 'Title', 'Viewer', 'BackgroundColor', [0, 0, 0], 'AutoResizeChildren', 'off');
            app.EvolutionOverlayTab = uitab(app.ViewerTabs, 'Title', 'Evolution Overlay', 'BackgroundColor', [0, 0, 0], 'AutoResizeChildren', 'off');
            
            %Populate the Viewer Tab
            app.PreviousFrameButton = uibutton(app.ViewerTab, 'push', 'Text', 'PREVIOUS', 'FontName', 'Roboto', 'FontSize', 10', 'FontColor', [1 1 1],...
                'Icon', 'baseline_skip_previous_white_48dp.png', 'IconAlignment', 'top', 'VerticalAlignment', 'bottom', 'Position', [5 5 55 55], 'BackgroundColor', ...
                [0 0.29 1]);
            app.PreviousFrameButton.ButtonPushedFcn = createCallbackFcn(app, @PreviousButtonPushed, true);
            app.NextFrameButton = uibutton(app.ViewerTab, 'push', 'Text', 'NEXT', 'FontName', 'Roboto', 'FontSize', 10, 'FontColor', [1 1 1], ...
                'Icon', 'baseline_skip_next_white_48dp.png', 'IconAlignment', 'top', 'VerticalAlignment', 'bottom', 'Position', [840 5 55 55], ...
                'BackgroundColor', [0 0.29 1]);
            app.NextFrameButton.ButtonPushedFcn = createCallbackFcn(app, @NextButtonPushed, true);
            app.JumpFrameLabel = uilabel(app.ViewerTab, 'Text', "JUMP TO", 'FontName', 'Roboto Medium', 'FontColor', [1 1 1], ...
                'FontSize', 14, 'Position', [100, 5, 60, 20]);
            app.JumpFrameField = uieditfield(app.ViewerTab, 'numeric', 'Value', 1, 'Limits', [1 Inf], 'FontName', 'Roboto Medium', 'FontColor', [1 1 1], ...
                'BackgroundColor', [0 0 0], 'Position', [165, 5, 40, 20]);
            app.JumpFrameField.ValueChangedFcn = createCallbackFcn(app, @JumpFrameFieldValueChanged, true);
            app.FrameInspectorButton = uibutton(app.ViewerTab, 'push', 'FontName', 'Roboto Medium', 'FontSize', 12, ...
                'Text', 'INSPECT FRAME', 'FontColor', [1 1 1], 'Position', [100, 30, 105, 20], 'BackgroundColor', [0, 0.29, 1]);
            app.FrameInspectorButton.ButtonPushedFcn = createCallbackFcn(app, @FrameInspectorButtonPushed, true);
            app.MainPlot = uiaxes(app.ViewerTab, 'DataAspectRatio', [1 1 1], 'FontName', 'Roboto', 'FontSize', 14, 'YDir', 'reverse', 'Box', 'on', ...
                'BoxStyle', 'full', 'XTick', [], 'YTick', [], 'Position', [5, 60, 890, 679], 'Color', [0 0 0], 'BackgroundColor', [0 0 0], 'XColor', ...
                [1 1 1], 'YColor', [1 1 1], 'AmbientLightColor', [0 0 0]);
            disableDefaultInteractivity(app.MainPlot);
            
            %Populate the Evolution Overlay Tab
            app.EvolutionFirst = uilabel(app.EvolutionOverlayTab, 'Text', 'FIRST FRAME', 'FontColor', [178, 24, 43]./255, 'FontName', 'Roboto Medium', ...
                'FontSize', 14, 'Position', [10, 5, 100, 40]);
            app.EvolutionLast = uilabel(app.EvolutionOverlayTab, 'Text', 'LAST FRAME', 'FontColor', [33, 102, 172]./255, 'FontName', 'Roboto Medium', ...
                'FontSize', 14, 'Position', [810, 5, 100, 40]);
            app.EvolutionPlot = uiaxes(app.EvolutionOverlayTab, 'AmbientLightColor', [0 0 0], 'XColor', [1 1 1], 'YColor', [1 1 1], 'Color', [0 0 0], ...
                'BackgroundColor', [0 0 0], 'Position', [10, 50, 880, 689], 'DataAspectRatio', [1 1 1], 'Box', 'on', 'XTick', [], 'YTick', [], 'YDir', 'reverse');
            title(app.EvolutionPlot, "PERIMETER EVOLUTION OVERLAY", 'FontName', 'Roboto Medium', 'Color', [1 1 1]);
            
            drawnow;
            app.UIFigure.WindowState = 'maximized';
            app.UIFigure.Visible = 'on';
            
            function toggleClicked(src, ~)
                if src.UserData == 1
                    src.UserData = 0;
                    src.ImageSource = 'baseline_toggle_off_white_48dp.png';
                elseif src.UserData == 0
                    src.UserData = 1;
                    src.ImageSource = 'baseline_toggle_on_white_48dp.png';
                end
            end
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = InCA

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
            clear;
        end
    end
end