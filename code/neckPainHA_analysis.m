% code for neck pain Pfizer study

Pfizer_dataBasePath = getpref('neckPainHA','pfizerDataPath');

load([Pfizer_dataBasePath 'Pfizer_data013123.mat'])

%% clean raw data

data = data_raw(data_raw.redcap_repeat_instrument~='visit_diagnoses' & ...
    data_raw.redcap_repeat_instrument~='imaging',:); % removes imaging and follow up visits

%% apply exclusion criteria

data_age = data(data.age>=6 & data.age<18,:); % age criteria

pain_loc = sum(table2array(data_age(:,102:111)),2); % pain location was filled out (neck pain)
assoc_oth_sx = sum(table2array(data_age(:,211:224)),2); % associated symptoms were filled out (neck pain)
data_comp = data_age((pain_loc>0 | assoc_oth_sx>0) & (data_age.p_current_ha_pattern=='episodic'|data_age.p_current_ha_pattern=='cons_same'|data_age.p_current_ha_pattern=='cons_flare'),:);
data_incomp = data_age((pain_loc==0 & assoc_oth_sx==0) | (data_age.p_current_ha_pattern~='episodic' & data_age.p_current_ha_pattern~='cons_same' & data_age.p_current_ha_pattern~='cons_flare'),:);

%% Define main outcome, and main predictor variables

% Neck pain, main outcome variable
data_comp.neckPain = zeros(height(data_comp),1);
data_comp.neckPain(data_comp.p_location_area___neck==1 | data_comp.p_assoc_sx_oth_sx___neck_pain==1) = 1;

% Daily/continuous headache, main predictor variable
data_comp.dailycont = zeros(height(data_comp),1);
data_comp.dailycont(data_comp.p_current_ha_pattern=='cons_same' | data_comp.p_current_ha_pattern=='cons_flare' | data_comp.p_fre_bad=='daily' | data_comp.p_fre_bad=='always') = 1;

% convert PedMIDAS score to grade
data_comp.pedmidas_grade = NaN*ones(height(data_comp),1);
data_comp.pedmidas_grade(data_comp.p_pedmidas_score<=10) = 0;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>10 & data_comp.p_pedmidas_score<=30) = 1;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>30 & data_comp.p_pedmidas_score<=50) = 2;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>50) = 3;

% rank bad headache frequency
data_comp.freq_bad = NaN*ones(height(data_comp),1);
data_comp.freq_bad (data_comp.p_fre_bad=='never') = 1;
data_comp.freq_bad (data_comp.p_fre_bad=='1mo') = 2;
data_comp.freq_bad (data_comp.p_fre_bad=='1to3mo') = 3;
data_comp.freq_bad (data_comp.p_fre_bad=='1wk') = 4;
data_comp.freq_bad (data_comp.p_fre_bad=='2to3wk') = 5;
data_comp.freq_bad (data_comp.p_fre_bad=='3wk') = 6;
data_comp.freq_bad (data_comp.p_fre_bad=='daily') = 7;
data_comp.freq_bad (data_comp.p_fre_bad=='always') = 8;

% categorize pain quality types
data_comp.pulsate = sum(table2array(data_comp(:,[85 86 95])),2);
data_comp.pulsate(data_comp.pulsate>1) = 1;
data_comp.pressure = sum(table2array(data_comp(:,[88:90 93])),2);
data_comp.pressure(data_comp.pressure>1) = 1;
data_comp.neuralgia = sum(table2array(data_comp(:,[87 91 92 94])),2);
data_comp.neuralgia(data_comp.neuralgia>1) = 1;

% rank severity grade
data_comp.severity_grade = NaN*ones(height(data_comp),1);
data_comp.severity_grade(data_comp.p_sev_overall=='mild') = 1;
data_comp.severity_grade(data_comp.p_sev_overall=='mod') = 2;
data_comp.severity_grade(data_comp.p_sev_overall=='sev') = 3;

%% Demographics

% Age
age_neckPain = prctile(data_comp.age(data_comp.neckPain==1),[25,50,75]);
age_noNeckPain = prctile(data_comp.age(data_comp.neckPain==0),[25,50,75]);
[p,tbl,~] = kruskalwallis(data_comp.age,data_comp.neckPain);
fprintf('age: neck pain %3.1f [%3.1f, %3.1f], no neck pain %3.1f [%3.1f, %3.1f], Chi2 = %1.1f, p = %3.2d \n',[age_neckPain(2) age_neckPain(1) age_neckPain(3) age_noNeckPain(2) age_noNeckPain(1) age_noNeckPain(3) tbl{2,5} p]);

% Gender (most likely is sex assigned at birth, but need to confirm this, gender ID data is not currently available)
[tbl,chi2,p] = crosstab(data_comp.gender,data_comp.neckPain);
fprintf('sex assigned at birth: neck pain F = %3i M = %3i, no neck pain F = %3i M = %3i, Chi2 = %1.1f, p = %3.2d \n',[tbl(1,2) tbl(2,2) tbl(1,1) tbl(2,1) chi2 p]);

% Race
[tbl,chi2,p] = crosstab(data_comp.race,data_comp.neckPain);
fprintf('race: neck pain W = %3i B = %3i A = %3i AI = %3i PI = %3i UNK = %3i NA = %3i, no neck pain W = %3i B = %3i A = %3i AI = %3i PI = %3i UNK = %3i NA = %3i; Chi2 = %1.1f, p = %3.2d \n',...
    [tbl(7,2) tbl(3,2) tbl(2,2) tbl(1,2) tbl(5,2) tbl(6,2) tbl(4,2) tbl(7,1) tbl(3,1) tbl(2,1) tbl(1,1) tbl(5,1) tbl(6,1) tbl(4,1) chi2 p]);

% ethnicity
[tbl,chi2,p] = crosstab(data_comp.ethnicity,data_comp.neckPain);
fprintf('ethnicity: neck pain H = %3i NH = %3i UNK = %3i NA = %3i, no neck pain H = %3i NH = %3i UNK = %3i NA = %3i; Chi2 = %1.1f, p = %3.2d \n',...
    [tbl(1,2) tbl(3,2) tbl(2,2) tbl(4,2) tbl(1,1) tbl(3,1) tbl(2,1) tbl(4,1) chi2 p]);


%% Headache characteristics

% main predictor - daily/continuous vs. intermittent
[tbl,chi2,p] = crosstab(data_comp.dailycont,data_comp.neckPain);
fprintf('daily continuous: neck pain daily/cont = %3i not cont = %3i, no neck pain daily/cont = %3i not cont = %3i, Chi2 = %1.1f, p = %3.2d \n',[tbl(2,2) tbl(1,2) tbl(2,1) tbl(1,1) chi2 p]);

[p,tbl,~] = kruskalwallis(data_comp.pedmidas_grade,data_comp.neckPain);
fprintf('pedmidas vs. neck pain: Chi2 = %1.1f, p = %3.2d \n',[tbl{2,5} p]);

[p,tbl,~] = kruskalwallis(data_comp.severity_grade,data_comp.neckPain);
fprintf('overall severity vs. neck pain: Chi2 = %1.1f, p = %3.2d \n',[tbl{2,5} p]);

[p,tbl,~] = kruskalwallis(data_comp.freq_bad,data_comp.neckPain);
fprintf('frequency of bad headaches vs. neck pain: Chi2 = %1.1f, p = %3.2d \n',[tbl{2,5} p]);

% Pain quality
[tbl,chi2,p] = crosstab(data_comp.neuralgia,data_comp.neckPain);
fprintf('neuralgiform: neck pain neuralgia = %3i no neuralgia = %3i, no neck pain neuralgia = %3i no neuralgia = %3i, Chi2 = %1.1f, p = %3.2d \n',[tbl(2,2) tbl(1,2) tbl(2,1) tbl(1,1) chi2 p]);

[tbl,chi2,p] = crosstab(data_comp.pressure,data_comp.neckPain);
fprintf('pressure: neck pain pressure = %3i no pressure = %3i, no neck pain pressure = %3i no pressure = %3i, Chi2 = %1.1f, p = %3.2d \n',[tbl(2,2) tbl(1,2) tbl(2,1) tbl(1,1) chi2 p]);

[tbl,chi2,p] = crosstab(data_comp.pulsate,data_comp.neckPain);
fprintf('pulsate: neck pain pulsate = %3i no pulsate = %3i, no neck pain pulsate = %3i no pulsate = %3i, Chi2 = %1.1f, p = %3.2d \n',[tbl(2,2) tbl(1,2) tbl(2,1) tbl(1,1) chi2 p]);
