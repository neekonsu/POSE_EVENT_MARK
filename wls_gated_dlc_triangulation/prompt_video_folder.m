function videosFolderPath = prompt_video_folder()
    disp('[I] Prompt user to select videos path');
    % Prompt the user to select a folder
    videosFolderPath = uigetdir("*", "Select videos folder inside DLC Project");
    
    % Check if the user selected a folder or cancelled the operation
    if videosFolderPath == 0
        disp('User cancelled the folder selection.');
    else
        disp(['Selected folder: ', videosFolderPath]);
    end
end