% code for neck pain Pfizer study

Pfizer_dataBasePath = getpref('neckPainHA','pfizerDataPath');

load([Pfizer_dataBasePath 'Pfizer_data013123.mat'])

%% clean raw data

data = data_raw(data_raw.redcap_repeat_instrument~='visit_diagnoses' & ...
    data_raw.redcap_repeat_instrument~='imaging',:); % removes imaging and follow up visits

%% apply exclusion criteria

data_age = data(data.age>=6 & data.age<18,:); % age criteria

psych_ros = sum(table2array(data_age(:,445:457)),2); % questions on psychiatric diagnoses was entered

data_comp = data_age(psych_ros>0 & ~isnan(data_age.p_pedmidas_score),:);
data_incomp = data_age(psych_ros==0 | isnan(data_age.p_pedmidas_score),:);

%% Define main outcome, and main predictor variables

% Pedmidas, main outcome variable, convert PedMIDAS score to grade
data_comp.pedmidas_grade = NaN*ones(height(data_comp),1);
data_comp.pedmidas_grade(data_comp.p_pedmidas_score<=10) = 0;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>10 & data_comp.p_pedmidas_score<=30) = 1;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>30 & data_comp.p_pedmidas_score<=50) = 2;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>50) = 3;

% Categorize main predictor variable, anxiety only, depression only, both,
% neither
data_comp.anxdep = NaN*ones(height(data_comp),1);
data_comp.anxdep(data_comp.p_psych_prob___anxiety==0 & data_comp.p_psych_prob___depress==0) = 0;
data_comp.anxdep(data_comp.p_psych_prob___anxiety==1 & data_comp.p_psych_prob___depress==0) = 1;
data_comp.anxdep(data_comp.p_psych_prob___anxiety==0 & data_comp.p_psych_prob___depress==1) = 2;
data_comp.anxdep(data_comp.p_psych_prob___anxiety==1 & data_comp.p_psych_prob___depress==1) = 3;

data_comp.anxdep = categorical(data_comp.anxdep,[0 1 2 3],{'neither','anxiety','depression','anxietydepression'});

% Determine daily/continuous headache
data_comp.dailycont = zeros(height(data_comp),1);
data_comp.dailycont(data_comp.p_current_ha_pattern=='cons_same' | data_comp.p_current_ha_pattern=='cons_flare' | data_comp.p_fre_bad=='daily' | data_comp.p_fre_bad=='always') = 1;

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

% rank severity grade
data_comp.severity_grade = NaN*ones(height(data_comp),1);
data_comp.severity_grade(data_comp.p_sev_overall=='mild') = 1;
data_comp.severity_grade(data_comp.p_sev_overall=='mod') = 2;
data_comp.severity_grade(data_comp.p_sev_overall=='sev') = 3;

%% Demographics

% Age
age_none = prctile(data_comp.age(data_comp.anxdep=='neither'),[25,50,75]);
fprintf('age no anxiety/depression %3.1f [%3.1f, %3.1f]\n',[age_none(2) age_none(1) age_none(3)]);
age_anx = prctile(data_comp.age(data_comp.anxdep=='anxiety'),[25,50,75]);
fprintf('age anxiety %3.1f [%3.1f, %3.1f]\n',[age_anx(2) age_anx(1) age_anx(3)]);
age_dep = prctile(data_comp.age(data_comp.anxdep=='depression'),[25,50,75]);
fprintf('age depression %3.1f [%3.1f, %3.1f]\n',[age_dep(2) age_dep(1) age_dep(3)]);
age_anxdep = prctile(data_comp.age(data_comp.anxdep=='anxietydepression'),[25,50,75]);
fprintf('age anxiety+depression %3.1f [%3.1f, %3.1f]\n',[age_anxdep(2) age_anxdep(1) age_anxdep(3)]);
[p,tbl,~] = kruskalwallis(data_comp.age,data_comp.anxdep);
fprintf('age vs. anx/dep Chi2 = %1.1f, p = %3.2d \n',[tbl{2,5} p]);

% Gender (most likely is sex assigned at birth, but need to confirm this, gender ID data is not currently available)
[tbl,chi2,p] = crosstab(data_comp.gender,data_comp.anxdep);
disp(tbl)
fprintf('sex assigned at birth vs. anxdep Chi2 = %1.1f, p = %3.2d \n',[chi2 p]);

%% Comparison with headache burden metrics

% primary outcome PedMIDAS
[p,tbl,stats] = kruskalwallis(data_comp.pedmidas_grade,data_comp.anxdep);
multcompare(stats)
fprintf('pedmidas vs. anxiety/depression: Chi2 = %1.1f, p = %3.2d \n',[tbl{2,5} p]);

% Headache pattern
[tbl,chi2,p] = crosstab(data_comp.dailycont,data_comp.anxdep)

% severity grade
[p,tbl,stats] = kruskalwallis(data_comp.severity_grade,data_comp.anxdep);
multcompare(stats)
fprintf('overall headache severity vs. anxiety/depression: Chi2 = %1.1f, p = %3.2d \n',[tbl{2,5} p]);

% frequency of bad headaches
[p,tbl,stats] = kruskalwallis(data_comp.freq_bad,data_comp.anxdep);
multcompare(stats)
fprintf('bad headache frequency vs. anxiety/depression: Chi2 = %1.1f, p = %3.2d \n',[tbl{2,5} p]);