# OUTPUT FORMAT FOR PIPELINE RESULTS

## ECoG DATA (NS5/NS6) STRUCT

(See 'openNSxCervical' helper function for full list of default fields)
Additional fields added by pipeline:

++ triggers.startSample
++ triggers.startFrame
++ triggers.endSample
++ triggers.endFrame

## 3D TRAJECTORY STRUCT

(TODO: ENTER HERE EXISTING FIELDS)
Additional Fields:
++ trajectory.likelihood: average likelihood of points used to construct each 3D point (helps place context of generated 3D points in original 2D estimation results)

## EVENT MARKS STRUCT

(TODO: ENTER HERE EXISTING FIELDS)
Additional Fields:
++ trajectory.(bodypart).likelihood: likelihood corresponding to data from CSV



