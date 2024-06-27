function displayMatFileContents()
    % Select the .mat file using a file dialog
    [filename, pathname] = uigetfile("*.mat", "Select a .mat file to view");

    % Check if the user selected a file or canceled the dialog
    if isequal(filename, 0) || isequal(pathname, 0)
        disp('User canceled the file selection');
    else
        % Add the folder to the MATLAB path
        addpath(pathname);

        % Load the .mat file
        data = load(fullfile(pathname, filename));

        % Display variables in the .mat file
        disp('Variables in the .mat file:');
        whos('-file', fullfile(pathname, filename));

        % Display the structure of the loaded data
        disp('Structure of the loaded data:');
        disp(data);

        % Display field names of the struct
        disp('Field names of the struct:');
        disp(fieldnames(data));

        % Display a summary of the struct fields
        disp('Summary of the struct fields:');
        structfun(@(x) disp(x(1:min(5,end))), data, 'UniformOutput', false);

        % Additional display of array or large fields within the struct
        fields = fieldnames(data);
        for i = 1:numel(fields)
            fieldValue = data.(fields{i});
            if isstruct(fieldValue)
                disp(['| — ', fields{i}]);
                % Recursively print the first non-struct element with hierarchy
                printAllFields(fieldValue, 1);
            else
                disp(['| — ', fields{i}]);
                dispFieldValue(fieldValue, 1); % Display first 5 elements with indentation
            end
        end
    end
end

function printAllFields(structVar, level)
    fields = fieldnames(structVar);
    indent = repmat('    ', 1, level); % Spaces for hierarchy
    for i = 1:numel(fields)
        fieldValue = structVar.(fields{i});
        if isstruct(fieldValue)
            disp([indent, '| — ', fields{i}]);
            % Recursive call with increased level
            printAllFields(fieldValue, level + 1);
        else
            disp([indent, '| — ', fields{i}]);
            dispFieldValue(fieldValue, level + 1); % Display first 5 elements with indentation
        end
    end
end

function dispFieldValue(fieldValue, level)
    indent = repmat('    ', 1, level); % Spaces for hierarchy
    for j = 1:min(5, numel(fieldValue))
        disp([indent, num2str(fieldValue(j))]);
    end
end
displayMatFileContents();