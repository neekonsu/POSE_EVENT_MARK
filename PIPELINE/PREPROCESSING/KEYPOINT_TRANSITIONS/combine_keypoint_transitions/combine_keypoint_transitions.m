function [keypoint_transitions] = combine_keypoint_transitions(varargin)
    % COMBINE_KEYPOINT_TRANSITIONS
    % Take one or more keypoint transition arrays, and return
    % a consolidated array of keypoint shifts.
    % Consolidated array of keypoint shifts will be used to 
    % split keypoint tracking data across all keypoints
    % to create final set for a trial. The consolidated keypoints will
    % be included into the _TRJ.mat output from triangulation,
    % which will use the matrix of keypoints split by transition phase
    % to generate n projection matrices for n phases.
    % 
    % FORMAT
    % Inputs:
    % [1,23,45,53,77,...], [2,33,41,46,86,...], ... <~> Input arrays of transition times from single cameras
    % Outputs:
    % [1,2,23,33,41,45,46,53,77,86,...] <~> Output array combining transitions
    
    % Initialize an empty array to hold the combined transitions
    combined_transitions = [];
    
    % Loop through each input array and concatenate it to the combined array
    for i = 1:nargin
        combined_transitions = [combined_transitions, varargin{i}];
    end
    
    % Sort the combined array to get the consolidated keypoint transitions
    keypoint_transitions = sort(combined_transitions);
end