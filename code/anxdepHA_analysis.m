% code for neck pain Pfizer study

Pfizer_dataBasePath = getpref('neckPainHA','pfizerDataPath');

load([Pfizer_dataBasePath 'Pfizer_data013123.mat'])

%% clean raw data

data = data_raw(data_raw.redcap_repeat_instrument~='visit_diagnoses' & ...
    data_raw.redcap_repeat_instrument~='imaging',:); % removes imaging and follow up visits

%% apply exclusion criteria

data_age = data(data.age>=6 & data.age<18,:); % age criteria
data_start = data_age(data_age.p_current_ha_pattern=='episodic' | data_age.p_current_ha_pattern=='cons_same' | data_age.p_current_ha_pattern=='cons_flare' | ~isnan(data_age.p_pedmidas_score),:); % answered the first question, or pedmidas

data_start.ageY = floor(data_start.age);
% Reorder race categories to make white (largest group) the reference group
data_start.race = reordercats(data_start.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});

% Reorder ethnicity categories to make non-hispanic (largest group) the
% reference group
data_start.ethnicity = reordercats(data_start.ethnicity,{'no_hisp','hisp','no_answer','unk'});

psych_ros = sum(table2array(data_start(:,445:457)),2); % questions on psychiatric diagnoses was entered
data_start.psych_ros = psych_ros;
data_comp = data_start(psych_ros>0 & ~isnan(data_start.p_pedmidas_score),:);
data_incomp = data_start(psych_ros==0 | isnan(data_start.p_pedmidas_score),:);

data_comp.complete = ones(height(data_comp),1);
data_incomp.complete = zeros(height(data_incomp),1);

comp_incomp = [data_comp;data_incomp];
%% Define main outcome, and main predictor variables

% Pedmidas, main outcome variable, convert PedMIDAS score to grade
data_comp.pedmidas_grade = NaN*ones(height(data_comp),1);
data_comp.pedmidas_grade(data_comp.p_pedmidas_score<=10) = 1;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>10 & data_comp.p_pedmidas_score<=30) = 2;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>30 & data_comp.p_pedmidas_score<=50) = 3;
data_comp.pedmidas_grade(data_comp.p_pedmidas_score>50) = 4;

% Categorize main predictor variable, anxiety only, depression only, both,
% neither
data_comp.anxdep = NaN*ones(height(data_comp),1);
data_comp.anxdep(data_comp.p_psych_prob___anxiety==0 & data_comp.p_psych_prob___depress==0) = 0;
data_comp.anxdep(data_comp.p_psych_prob___anxiety==1 & data_comp.p_psych_prob___depress==0) = 1;
data_comp.anxdep(data_comp.p_psych_prob___anxiety==0 & data_comp.p_psych_prob___depress==1) = 2;
data_comp.anxdep(data_comp.p_psych_prob___anxiety==1 & data_comp.p_psych_prob___depress==1) = 3;
data_comp.anxdep2 = data_comp.anxdep;
data_comp.anxdep = categorical(data_comp.anxdep,[0 1 2 3],{'neither','anxiety','depression','anxietydepression'});

data_comp.anxiety = NaN*ones(height(data_comp),1);
data_comp.anxiety(data_comp.p_psych_prob___anxiety==0) = 0;
data_comp.anxiety(data_comp.p_psych_prob___anxiety==1) = 1;

data_comp.depression = NaN*ones(height(data_comp),1);
data_comp.depression(data_comp.p_psych_prob___depress==0) = 0;
data_comp.depression(data_comp.p_psych_prob___depress==1) = 1;

% Determine who has seen a behavioral health provider
data_comp.bh_provider (data_comp.p_psych_prob___sw==1|data_comp.p_psych_prob___psychol==1|data_comp.p_psych_prob___psychi==1) = 1;

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

% categorize pain quality types
data_comp.pulsate = sum(table2array(data_comp(:,[85 86 95])),2);
data_comp.pulsate(data_comp.pulsate>1) = 1;
data_comp.pressure = sum(table2array(data_comp(:,[88:90 93])),2);
data_comp.pressure(data_comp.pressure>1) = 1;
data_comp.neuralgia = sum(table2array(data_comp(:,[87 91 92 94])),2);
data_comp.neuralgia(data_comp.neuralgia>1) = 1;

% Determine if valsalva is a trigger for headache
data_comp.valsalva = sum(table2array(data_comp(:,158:160)),2);
data_comp.valsalva(data_comp.valsalva>0) = 1;

% determine total count for triggers (overall 26 total possible)
data_comp.triggerN = sum(table2array(data_comp(:,[129:151 161 162 627])),2);

% determine total count for associated symptoms (overall 13 total possible)
data_comp.assocSxN = sum(table2array(data_comp(:,[170 171 207 209 212:217 219 221 222])),2);


%% Headache diagnosis
data_comp.p_con_pattern_duration = categorical(data_comp.p_con_pattern_duration);
data_comp.p_epi_fre_dur = categorical(data_comp.p_epi_fre_dur,[1 2 3],{'2wk','1mo','3mo'});
ICHD3 = ichd3_Dx(data_comp);
ICHD3.dx = mergecats(ICHD3.dx,{'tth','chronic_tth'});
ICHD3.dx = mergecats(ICHD3.dx,{'ndph','new_onset'});

%% Robust linear regression
% predictor variable: presence of anxiety and/or depression
mdl_sex = fitlm(data_comp,'age ~ anxdep','RobustOpts','on');
a = ExpCalc95fromSE(table2array(mdl_sex.Coefficients(2,1)),table2array(mdl_sex.Coefficients(2,2)));
disp(['sex: ' num2str(a(1)) ' [' num2str(a(2)) ', ' num2str(a(3)) ']'])

mdl_age = fitlm(data_comp,'p_pedmidas_score ~ age','RobustOpts','on');
a = ExpCalc95fromSE(table2array(mdl_age.Coefficients(2,1)),table2array(mdl_age.Coefficients(2,2)));
disp(['age: ' num2str(a(1)) ' [' num2str(a(2)) ', ' num2str(a(3)) ']'])

mdl_race = fitlm(data_comp,'p_pedmidas_score ~ race','RobustOpts','on');


mdl_ethnicity = fitlm(data_comp,'p_pedmidas_score ~ ethnicity','RobustOpts','on');
mdl_anxdep_disability = fitlm(data_comp,'p_pedmidas_score ~ anxdep','RobustOpts','on');
mdl_anxdep_freq = fitlm(data_comp,'freq_bad ~ anxdep','RobustOpts','on');
mdl_anxdep_sev = fitlm(data_comp,'severity_grade ~ anxdep','RobustOpts','on');
mdl_anxdep_dailycont = fitlm(data_comp,'dailycont ~ anxdep','RobustOpts','on');
mdl_bh = fitlm(data_comp,'p_pedmidas_score ~ bh_provider','RobustOpts','on');
mdl_bh_anxdep = fitlm(data_comp,'p_pedmidas_score ~ bh_provider + anxdep','RobustOpts','on');

% Outcome variable


mdl_Mdisability = fitlm(data_comp,'p_pedmidas_score ~ gender + ageY + race + ethnicity + anxdep + bh_provider + dailycont + freq_bad + severity_grade','RobustOpts','on');
plotSlice(mdl_Mdisability)

mdl_MassocSx = fitlm(data_comp,'assocSxN ~ anxdep + gender + ageY + race + ethnicity + p_pedmidas_score + bh_provider','RobustOpts','on');
plotSlice(mdl_MassocSx)

mdl_Mtriggers = fitlm(data_comp,'triggerN ~ anxdep + gender + ageY + race + ethnicity + p_pedmidas_score + bh_provider','RobustOpts','on');
plotSlice(mdl_Mtriggers)


%% compare those who completed enough of the questionnaire to be included, vs. those who had incomplete information

mdl_incomp = fitglm(comp_incomp,'complete ~ ageY + gender + race + ethnicity','Distribution','binomial');