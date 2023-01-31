% code for neck pain Pfizer study

Pfizer_dataBasePath = getpref('neckPainHA','pfizerDataPath');

load([Pfizer_dataBasePath 'Pfizer_data013123.mat'])

%% clean raw data

data = data_raw(data_raw.redcap_repeat_instrument~='visit_diagnoses' & ...
    data_raw.redcap_repeat_instrument~='imaging',:); % removes imaging and follow up visits

%% apply exclusion criteria


%% Neck pain
neckPain = data(data.p_location_area___neck==1 | data.p_assoc_sx_oth_sx___neck_pain==1,:);
no_neckPain = data(data.p_location_area___neck==0 & data.p_assoc_sx_oth_sx___neck_pain==0,:);