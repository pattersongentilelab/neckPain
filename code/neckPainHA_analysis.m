% code for neck pain Pfizer study

Pfizer_dataBasePath = getpref('neckPainHA','pfizerDataPath');

load([Pfizer_dataBasePath 'Pfizer_data013123.mat'])

%% clean raw data

data = data_raw(data_raw.redcap_repeat_instrument~='visit_diagnoses' & ...
    data_raw.redcap_repeat_instrument~='imaging',:); % removes imaging and follow up visits

%% apply exclusion criteria

data_age = data(data.age>=6 & data.age<18,:); % age criteria
data_start = data_age(data_age.p_current_ha_pattern=='episodic' | data_age.p_current_ha_pattern=='cons_same' | data_age.p_current_ha_pattern=='cons_flare',:); % started the questionnaire

% Convert age to years
data_start.ageY = floor(data_start.age);

% Reorder race categories to make white (largest group) the reference group
data_start.race = reordercats(data_start.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});

% Reorder ethnicity categories to make non-hispanic (largest group) the
% reference group
data_start.ethnicity = reordercats(data_start.ethnicity,{'no_hisp','hisp','no_answer','unk'});

pain_loc = sum(table2array(data_start(:,102:111)),2); % pain location was filled out (neck pain)
assoc_oth_sx = sum(table2array(data_start(:,211:224)),2); % associated symptoms were filled out (neck pain)
data_comp = data_start(pain_loc>0 | assoc_oth_sx>0,:);
data_incomp = data_start(pain_loc==0 & assoc_oth_sx==0,:);

data_comp.complete = ones(height(data_comp),1);
data_incomp.complete = zeros(height(data_incomp),1);

comp_incomp = [data_comp;data_incomp];

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

% rank severity grade
data_comp.severity_grade = NaN*ones(height(data_comp),1);
data_comp.severity_grade(data_comp.p_sev_overall=='mild') = 1;
data_comp.severity_grade(data_comp.p_sev_overall=='mod') = 2;
data_comp.severity_grade(data_comp.p_sev_overall=='sev') = 3;

% activity as a trigger
data_comp.active = NaN*ones(height(data_comp),1);
data_comp.active(data_comp.p_activity == 'feel_worse' | data_comp.p_trigger___exercise==0) = 1;
data_comp.active((data_comp.p_activity == 'feel_better' | data_comp.p_activity == 'no_change' | data_comp.p_activity == 'move') & data_comp.p_trigger___exercise==0) = 0;

% Determine if valsalva is a trigger for headache
data_comp.valsalva = sum(table2array(data_comp(:,158:160)),2);
data_comp.valsalva(data_comp.valsalva>0) = 1;

% Determine if headache is positional
data_comp.position = zeros(height(data_comp),1);
data_comp.position(data_comp.p_valsalva_position___stand==0 & data_comp.p_valsalva_position___lie==0 & (data_comp.p_valsalva_position___none==1 | data_comp.valsalva==1)) = 1;
data_comp.position(data_comp.p_valsalva_position___stand==1 & data_comp.p_valsalva_position___lie==0) = 2;
data_comp.position(data_comp.p_valsalva_position___stand==0 & data_comp.p_valsalva_position___lie==1) = 3;
data_comp.position(data_comp.p_valsalva_position___stand==1 & data_comp.p_valsalva_position___lie==1) = 4;
data_comp.position = categorical(data_comp.position,[1 2 3 4 0],{'neither','worse_stand','worse_lie','both','missing'});
data_comp.position = removecats(data_comp.position,{'missing'});

% Determine pain laterality
data_comp.pain_lat = zeros(height(data_comp),1);
data_comp.pain_lat(data_comp.p_location_side___left==1 & data_comp.p_location_side___right==0 & data_comp.p_location_side___both==0) = 1;
data_comp.pain_lat(data_comp.p_location_side___left==0 & data_comp.p_location_side___right==1 & data_comp.p_location_side___both==0) = 1;
data_comp.pain_lat(data_comp.p_location_side___left==1 & data_comp.p_location_side___right==1 & data_comp.p_location_side___both==0) = 2;
data_comp.pain_lat(data_comp.p_location_side___left==0 & data_comp.p_location_side___right==0 & data_comp.p_location_side___both==1) = 3;
data_comp.pain_lat(data_comp.p_location_side___left==1 & data_comp.p_location_side___right==1 & data_comp.p_location_side___both==1) = 4;
data_comp.pain_lat(data_comp.p_location_side___left==1 & data_comp.p_location_side___right==0 & data_comp.p_location_side___both==1) = 4;
data_comp.pain_lat(data_comp.p_location_side___left==0 & data_comp.p_location_side___right==1 & data_comp.p_location_side___both==1) = 4;
data_comp.pain_lat(data_comp.p_location_side___cant_desc==1 & data_comp.p_location_side___left==0 & data_comp.p_location_side___right==0 & data_comp.p_location_side___both==0) = 5;
data_comp.pain_lat = categorical(data_comp.pain_lat,[3 1 2 4 5 0],{'bilateral','side_lock','uni_alt','combination','cant_desc','missing'});
data_comp.pain_lat = removecats(data_comp.pain_lat,{'missing'});





%% Headache diagnosis
data_comp.p_con_pattern_duration = categorical(data_comp.p_con_pattern_duration);
data_comp.p_epi_fre_dur = categorical(data_comp.p_epi_fre_dur,[1 2 3],{'2wk','1mo','3mo'});

ICHD3 = ichd3_Dx(data_comp);

ICHD3.dx = reordercats(ICHD3.dx,{'migraine','chronic_migraine','prob_migraine','tth','chronic_tth','tac','new_onset','ndph','pth','other_primary','undefined'});
figure
histogram(ICHD3.dx)

data_comp.pulsate = ICHD3.pulsate;
data_comp.pressure = ICHD3.pressure;
data_comp.neuralgia = ICHD3.neuralgia;
data_comp.ICHD3dx = ICHD3.dx;

%% Binary logistic regression

% univariate
mdl_age = fitglm(data_comp,'neckPain ~ ageY','Distribution','binomial');
a = ExpCalc95fromSE(table2array(mdl_age.Coefficients(2,1)),table2array(mdl_age.Coefficients(2,2)));
disp(['age: ' num2str(a(1)) ' [' num2str(a(2)) ', ' num2str(a(3)) ']'])

mdl_sex = fitglm(data_comp,'neckPain ~ gender','Distribution','binomial');
a = ExpCalc95fromSE(table2array(mdl_sex.Coefficients(2,1)),table2array(mdl_sex.Coefficients(2,2)));
disp(['sex: ' num2str(a(1)) ' [' num2str(a(2)) ', ' num2str(a(3)) ']'])

mdl_race = fitglm(data_comp,'neckPain ~ race','Distribution','binomial');a = ExpCalc95fromSE(table2array(mdl_sex.Coefficients(2,1)),table2array(mdl_sex.Coefficients(2,2)));
disp(['race: ' num2str(a(1)) ' [' num2str(a(2)) ', ' num2str(a(3)) ']'])

mdl_ethnicity = fitglm(data_comp,'neckPain ~ ethnicity','Distribution','binomial');
mdl_severity = fitglm(data_comp,'neckPain ~ severity_grade','Distribution','binomial');
mdl_disability = fitglm(data_comp,'neckPain ~ pedmidas_grade','Distribution','binomial');
mdl_freq_bad = fitglm(data_comp,'neckPain ~ freq_bad','Distribution','binomial');
mdl_cont = fitglm(data_comp,'neckPain ~ dailycont','Distribution','binomial');
mdl_pain_lat = fitglm(data_comp,'neckPain ~ pain_lat','Distribution','binomial');
mdl_pressure = fitglm(data_comp,'neckPain ~ pressure','Distribution','binomial');
mdl_pulsate = fitglm(data_comp,'neckPain ~ pulsate','Distribution','binomial');
mdl_neuralgia = fitglm(data_comp,'neckPain ~ neuralgia','Distribution','binomial');
mdl_active = fitglm(data_comp,'neckPain ~ active','Distribution','binomial');
mdl_valsalva = fitglm(data_comp,'neckPain ~ valsalva','Distribution','binomial');
mdl_position = fitglm(data_comp,'neckPain ~ position','Distribution','binomial');
mdl_dx = fitglm(data_comp,'neckPain ~ ICHD3dx','Distribution','binomial');


% multivariate
mdl_Mult = fitglm(data_comp,'neckPain ~ ageY + gender + race + ethnicity + dailycont + severity_grade + pedmidas_grade + pain_lat + position + valsalva + active + pulsate + pressure + neuralgia + freq_bad + ICHD3dx','Distribution','binomial');

%% compare those who completed enough of the questionnaire to be included, vs. those who had incomplete information

mdl_incomp = fitglm(comp_incomp,'complete ~ ageY + gender + race + ethnicity','Distribution','binomial');