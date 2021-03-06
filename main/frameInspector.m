classdef frameInspector < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        InCAFrameInspectorUIFigure  matlab.ui.Figure
        ThreeDViewer                matlab.ui.control.UIAxes
        TwoDViewer                  matlab.ui.control.UIAxes
    end
    
    % Callbacks that handle component events
    methods (Access = private)
        
        % Code that executes after component creation
        function startupFcn(app, image, ~, maskInformation, didFit, minArcLength, orientation)
            f = uiprogressdlg(app.InCAFrameInspectorUIFigure, 'Title', 'Please wait', 'Message', 'Generating plots...', 'Indeterminate',"on", "Icon",  "none");
            drawnow;
            %InCAFrameInspectorUIFigureSizeChanged(app, 23);
            imshow(image, 'Parent', app.TwoDViewer);
            hold(app.TwoDViewer, 'on');
            [~, views] = size(info);
            for i = 1:views
                perimeterPoints = maskInformation(i).PerimeterPoints;
                center = maskInformation(i).Centroid;
                tracking = maskInformation(i).TrackingPoints;
                plot(app.TwoDViewer, perimeterPoints(:, 1), perimeterPoints(:, 2), 'r', 'LineWidth', 2, "DisplayName", 'Mask Perimeter');
                plot(app.TwoDViewer, center(1), center(2), 'b*', "LineWidth", 2, "MarkerSize", 5, "DisplayName", 'Centroid');
                plot(app.TwoDViewer, tracking(:, 1), tracking(:, 2), 'y*', 'LineWidth', 2, 'MarkerSize', 5, "DisplayName", 'Perimeter Tracking Points');
                if didFit
                    fourier = maskInformation(i).FourierPoints;
                    plot(app.TwoDViewer, fourier(:, 1), fourier(:, 2), 'c.', 'MarkerSize', 5, 'DisplayName', 'Fourier Fit Points', 'LineWidth', 2);
                    plot(app.TwoDViewer, maskInformation(i).xData, maskInformation(i).yData, '-g', 'LineWidth', 1, "DisplayName", "Fourier Fit", 'LineWidth', 2);
                end
                legend(app.TwoDViewer,'TextColor', 'white');
            end
            hold(app.TwoDViewer, 'off');
            
            %% Three D Viewer
            hold(app.ThreeDViewer, 'on');
            if views  == 1
                translatedPoints = bubbleAnalysis.translatePerim(maskInformation(i).PerimeterPoints, maskInformation(i).Centroid);
                rotatedPoints = bubbleAnalysis.rotatePerim(translatedPoints, orientation);
                surfPoints = bubbleAnalysis.genSurface(rotatedPoints, minArcLength);
                surf(surfPoints(:, 1), surfPoints(:, 2), surfPoints(:, 3), 'Parent', app.ThreeDViewer);
            end
            axis(app.ThreeDViewer, 'equal');
            hold(app.ThreeDViewer, 'off');
            drawnow;
            close(f);
        end
        
        % Size changed function: InCAFrameInspectorUIFigure
        function InCAFrameInspectorUIFigureSizeChanged(app, ~)
            position = app.InCAFrameInspectorUIFigure.Position;
            app.TwoDViewer.Position = [0, 0, position(3)/2, position(4)];
            app.ThreeDViewer.Position = [position(3)/2, 0, position(3)/2, position(4)];
        end
    end
    
    % Component initialization
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            % Create InCAFrameInspectorUIFigure and hide until all components are created
            app.InCAFrameInspectorUIFigure = uifigure('Visible', 'off', 'AutoResizeChildren', 'off', 'Color', [0 0 0], 'WindowState', 'maximized', ...
                'Name', 'InCA Frame Inspector');
            app.InCAFrameInspectorUIFigure.SizeChangedFcn = createCallbackFcn(app, @InCAFrameInspectorUIFigureSizeChanged, true);
            position = app.InCAFrameInspectorUIFigure.Position;
            
            % Create ThreeDViewer
            cmap = viridis(256);
            app.ThreeDViewer = uiaxes(app.InCAFrameInspectorUIFigure, 'Colormap', plasma(256), 'AmbientLightColor', [0 0 0], 'FontName', 'Roboto', 'XColor', [0 0 0], ...
                'XTick', [], 'YColor', [0 0 0], 'YTick', [], 'ZColor', [0 0 0], 'ZTick', [], 'Color', [0 0 0], 'Box', 'on', ...
                'Position', [position(3)/2, 0, position(3)/2, position(4)]);
            
            % Create TwoDViewer
            app.TwoDViewer = uiaxes(app.InCAFrameInspectorUIFigure, 'AmbientLightColor', [0 0 0], 'FontName', 'Roboto', 'XColor', [1 1 1], 'XTick', [], ...
                'YColor', [1 1 1], 'YTick', [], 'Color', [0 0 0], 'Box', 'on', 'Position', [0, 0, position(3)/2, position(4)]);
            
            % Show the figure after all components are created
            app.InCAFrameInspectorUIFigure.Visible = 'on';
        end
    end
    
    % App creation and deletion
    methods (Access = public)
        
        % Construct app
        function app = frameInspector(varargin)
            
            % Create UIFigure and components
            createComponents(app)
            
            % Register the app with App Designer
            registerApp(app, app.InCAFrameInspectorUIFigure)
            
            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            
            if nargout == 0
                clear app
            end
        end
        
        % Code that executes before app deletion
        function delete(app)
            
            % Delete UIFigure when app is deleted
            delete(app.InCAFrameInspectorUIFigure)
        end
    end
end