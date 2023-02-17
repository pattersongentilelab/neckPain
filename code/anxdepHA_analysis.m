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

% Convert race and ethnicity into numbers

% Convert age to years
data_comp.ageY = floor(data_comp.age);

% Reorder race categories to make white (largest group) the reference group
data_comp.race = reordercats(data_comp.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});

% Reorder ethnicity categories to make non-hispanic (largest group) the
% reference group
data_comp.ethnicity = reordercats(data_comp.ethnicity,{'no_hisp','hisp','no_answer','unk'});

%% Headache diagnosis

ICHD3 = ichd3_Dx(data_comp);

[tbl,chi2,p] = crosstab(ICHD3.dx,data_comp.anxdep);
fprintf('dx: Chi2 = %1.1f, p = %3.2d \n',[chi2 p]);



%% Logistic regression
% predictor variables: presence of anxiety, depression, age, sex assigned at
% birth, race, ethnicity

mdl = fitlm(data_comp,'p_pedmidas_score ~ anxdep','RobustOpts','on');
plotSlice(mdl)

X = [data_comp.anxdep2];
Y = data_comp.pedmidas_grade;
[B,dev,stats] = mnrfit(X,Y,'Model','ordinal');

