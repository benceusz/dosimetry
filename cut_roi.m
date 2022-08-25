path_seq_with_roi = "/media/nraresearch/ben_usz/Dual_Split_Projekt/preprocessed_dual_split/1/33/7"
path_seq_with_no_roi = "/media/nraresearch/ben_usz/Dual_Split_Projekt/preprocessed_dual_split/1/66/6"

output_seq_with_no_roi = "/media/nraresearch/ben_usz/Dual_Split_Projekt/preprocessed_dual_split_newroi/1/66/6"

[im_33, info_33]=readCTSeries(path_seq_with_roi);
[im_66, info_66]=readCTSeries(path_seq_with_no_roi);


% TODO cut the -1024 part , mask

% keep the biggest connected neighbours


writeDicoms(output_seq_with_no_roi, im_66_cut, info_66, "66");
