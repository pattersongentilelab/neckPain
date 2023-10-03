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


% associated symptoms
data_comp.sensory_sensitivity = zeros(height(data_comp),1);
data_comp.sensory_sensitivity(data_comp.p_trigger___light==1 | data_comp.p_assoc_sx_oth_sx___light) = data_comp.sensory_sensitivity(data_comp.p_trigger___light==1 | data_comp.p_assoc_sx_oth_sx___light) + 1;
data_comp.sensory_sensitivity(data_comp.p_trigger___noises==1 | data_comp.p_assoc_sx_oth_sx___sound) = data_comp.sensory_sensitivity(data_comp.p_trigger___noises==1 | data_comp.p_assoc_sx_oth_sx___sound) + 1;
data_comp.sensory_sensitivity(data_comp.p_trigger___smells==1 | data_comp.p_assoc_sx_oth_sx___smell) = data_comp.sensory_sensitivity(data_comp.p_trigger___smells==1 | data_comp.p_assoc_sx_oth_sx___smell) + 1;

data_comp.lighthead = data_comp.p_assoc_sx_oth_sx___lighthead;
data_comp.spinning = data_comp.p_assoc_sx_oth_sx___spinning;
data_comp.balance = data_comp.p_assoc_sx_oth_sx___balance;
data_comp.ringing = data_comp.p_assoc_sx_oth_sx___ringing;
data_comp.thinking = data_comp.p_assoc_sx_oth_sx___think;
data_comp.blurry = data_comp.p_assoc_sx_vis___blur;

data_comp.tingling = zeros(height(data_comp),1);
data_comp.tingling((data_comp.p_assoc_sx_neur_uni___numb==1 | data_comp.p_assoc_sx_neur_uni___tingle==1) & (data_comp.p_assoc_sx_neur_bil___numb==0 & data_comp.p_assoc_sx_neur_bil___tingle==0)) = 1; % unilateral only
data_comp.tingling((data_comp.p_assoc_sx_neur_uni___numb==0 & data_comp.p_assoc_sx_neur_uni___tingle==0) & (data_comp.p_assoc_sx_neur_bil___numb==1 | data_comp.p_assoc_sx_neur_bil___tingle==1)) = 2; % bilateral only
data_comp.tingling((data_comp.p_assoc_sx_neur_uni___numb==1 | data_comp.p_assoc_sx_neur_uni___tingle==1) & (data_comp.p_assoc_sx_neur_bil___numb==1 | data_comp.p_assoc_sx_neur_bil___tingle==1)) = 3; % unilateral both
data_comp.tingling = categorical(data_comp.tingling,[0 1 2 3],{'none','unilateral_only','bilateral_only','both'});


data_comp.dysauto = zeros(height(data_comp),1);
data_comp.dysauto(data_comp.p_heart_prob___faint==1 | data_comp.p_heart_prob___pots==1) = 1;

data_comp.abd = zeros(height(data_comp),1);
data_comp.abd(data_comp.p_gi_prob___abd_pain==1) = 1;

%% Headache diagnosis
data_comp.p_con_pattern_duration = categorical(data_comp.p_con_pattern_duration);
data_comp.p_epi_fre_dur = categorical(data_comp.p_epi_fre_dur,[1 2 3],{'2wk','1mo','3mo'});

ICHD3 = ichd3_Dx(data_comp);
ICHD3.dx = reordercats(ICHD3.dx,{'migraine','chronic_migraine','prob_migraine','tth','chronic_tth','tac','new_onset','ndph','pth','other_primary','undefined'});
ICHD3.dx = mergecats(ICHD3.dx,{'tth','chronic_tth'});
ICHD3.dx = mergecats(ICHD3.dx,{'ndph','new_onset'});
ICHD3.dx = mergecats(ICHD3.dx,{'migraine','chronic_migraine','prob_migraine'});
data_comp.ichd3 = ICHD3.dx;

data_comp.pulsate = ICHD3.pulsate;
data_comp.pressure = ICHD3.pressure;
data_comp.neuralgia = ICHD3.neuralgia;
data_comp.ICHD3dx = ICHD3.dx;

%% Binary logistic regression

% univariable
mdl_age = fitglm(data_comp,'neckPain ~ ageY','Distribution','binomial');
mdl_sex = fitglm(data_comp,'neckPain ~ gender','Distribution','binomial');
mdl_race = fitglm(data_comp,'neckPain ~ race','Distribution','binomial');a = ExpCalc95fromSE(table2array(mdl_sex.Coefficients(2,1)),table2array(mdl_sex.Coefficients(2,2)));
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

mdl_lighthead = fitglm(data_comp,'neckPain ~ lighthead','Distribution','binomial');
mdl_ringing = fitglm(data_comp,'neckPain ~ ringing','Distribution','binomial');
mdl_spinning = fitglm(data_comp,'neckPain ~ spinning','Distribution','binomial');
mdl_balance = fitglm(data_comp,'neckPain ~ balance','Distribution','binomial');
mdl_thinking = fitglm(data_comp,'neckPain ~ thinking','Distribution','binomial');
mdl_blurry = fitglm(data_comp,'neckPain ~ blurry','Distribution','binomial');
mdl_sensory = fitglm(data_comp,'neckPain ~ sensory_sensitivity','Distribution','binomial');
mdl_tingling = fitglm(data_comp,'neckPain ~ tingling','Distribution','binomial');

mdl_dysauto = fitglm(data_comp,'neckPain ~ dysauto','Distribution','binomial');
mdl_abd = fitglm(data_comp,'neckPain ~ abd','Distribution','binomial');

% multivariable
mdl_Mult = fitglm(data_comp,...
    'neckPain ~ ageY + gender + race + ethnicity + dailycont + severity_grade + pedmidas_grade + freq_bad + pain_lat + active + valsalva + position + pulsate + pressure + neuralgia + lighthead + spinning + balance + ringing + thinking + blurry + sensory_sensitivity + tingling + ICHD3dx + dysauto + abd',...
    'Distribution','binomial');

% Remove non-significant covariates (p<0.1)
mdl_MultFinal = fitglm(data_comp,...
    'neckPain ~ ageY + gender + race + ethnicity + dailycont + pedmidas_grade + freq_bad +  active + position + pressure + balance + ringing + thinking + sensory_sensitivity + tingling + abd',...
    'Distribution','binomial');

%% plot regression analysis
figure

var = fliplr({'Age (years)','Sex assigned at birth','Race - Black','Race - Asian','Race - Unknown','Race - no answer','Ethnicity - Hispanic','Ethnicity - no answer',...
    'daily-continuous HA','HA severity (mild, moderate, severe)','PedMIDAS grade (none, mild, moderate, severe)','Frequency of bad HA','Pain laterality - unilateral side locked',...
    'Pain laterality - unilateral alternating','Pain laterality - combined','Pain laterality - cannot describe','Induced by exercise','Induced by Valsalva','Positional - worse lying',...
    'Positional - worse standing','Positional - worse lying and standing','Pain quality - pressure','Pain quality - pulsate','Pain quality - neuralgia','lightheadedness','room spinning',...
    'balance problems','ear ringing','Trouble thinking','blurry vision','sensory hypersensitivity','numbness/tingling unilateral','numbness/tingling bilateral','numbness/tingling both',...
    'ICHD3 - TTH','ICHD3 - TAC','ICHD3 - PTH','ICHD3 - NDPH','ICHD3 - Other primary','ICHD3 - Undefined','Comorbid POTS/dysautonomia','Comorbid abdominal pain'});
varNum = 1:1:length(var);

subplot(1,3,1)
hold on
title('Univariable')
ylabel('Predictor variable')
ax = gca; ax.Box = 'on'; ax.YTick = varNum; ax.YTickLabels = var; ax.YLim = [0 length(varNum)+1]; ax.XScale = 'log'; ax.XLim = [0.1 10]; ax.XTick = [0.1 1 10]; ax.XTickLabels = [0.1 1 10];

age95 = ExpCalc95fromSE(table2array(mdl_age.Coefficients(2,1)),table2array(mdl_age.Coefficients(2,2))); ageErr = [age95(1)  abs(diff(age95([1 2]))) abs(diff(age95([1 3])))];
sex95 = ExpCalc95fromSE(table2array(mdl_sex.Coefficients(2,1)),table2array(mdl_sex.Coefficients(2,2))); sexErr = [sex95(1)  abs(diff(sex95([1 2]))) abs(diff(sex95([1 3])))];

raceB95 = ExpCalc95fromSE(table2array(mdl_race.Coefficients(2,1)),table2array(mdl_race.Coefficients(2,2))); raceBErr = [raceB95(1) abs(diff(raceB95([1 2]))) abs(diff(raceB95([1 3])))];
raceA95 = ExpCalc95fromSE(table2array(mdl_race.Coefficients(3,1)),table2array(mdl_race.Coefficients(3,2))); raceAErr = [raceA95(1)  abs(diff(raceA95([1 2]))) abs(diff(raceA95([1 3])))];
raceNA95 = ExpCalc95fromSE(table2array(mdl_race.Coefficients(6,1)),table2array(mdl_race.Coefficients(6,2))); raceNAErr = [raceNA95(1)  abs(diff(raceNA95([1 2]))) abs(diff(raceNA95([1 3])))];
raceU95 = ExpCalc95fromSE(table2array(mdl_race.Coefficients(7,1)),table2array(mdl_race.Coefficients(7,2))); raceUErr = [raceU95(1)  abs(diff(raceU95([1 2]))) abs(diff(raceU95([1 3])))];

ethH95 = ExpCalc95fromSE(table2array(mdl_ethnicity.Coefficients(2,1)),table2array(mdl_ethnicity.Coefficients(2,2))); ethHErr = [ethH95(1)  abs(diff(ethH95([1 2]))) abs(diff(ethH95([1 3])))];
ethNA95 = ExpCalc95fromSE(table2array(mdl_ethnicity.Coefficients(3,1)),table2array(mdl_ethnicity.Coefficients(3,2))); ethNAErr = [ethNA95(1)  abs(diff(ethNA95([1 2]))) abs(diff(ethNA95([1 3])))];
cont95 = ExpCalc95fromSE(table2array(mdl_cont.Coefficients(2,1)),table2array(mdl_cont.Coefficients(2,2))); contErr = [cont95(1)  abs(diff(cont95([1 2]))) abs(diff(cont95([1 3])))];

sev95 = ExpCalc95fromSE(table2array(mdl_severity.Coefficients(2,1)),table2array(mdl_severity.Coefficients(2,2))); sevErr = [sev95(1)  abs(diff(sev95([1 2]))) abs(diff(sev95([1 3])))];
dis95 = ExpCalc95fromSE(table2array(mdl_disability.Coefficients(2,1)),table2array(mdl_disability.Coefficients(2,2))); disErr = [dis95(1)  abs(diff(dis95([1 2]))) abs(diff(dis95([1 3])))];
freq95 = ExpCalc95fromSE(table2array(mdl_freq_bad.Coefficients(2,1)),table2array(mdl_freq_bad.Coefficients(2,2))); freqErr = [freq95(1)  abs(diff(freq95([1 2]))) abs(diff(freq95([1 3])))];

plu95 = ExpCalc95fromSE(table2array(mdl_pain_lat.Coefficients(2,1)),table2array(mdl_pain_lat.Coefficients(2,2))); pluErr = [plu95(1)  abs(diff(plu95([1 2]))) abs(diff(plu95([1 3])))];
pla95 = ExpCalc95fromSE(table2array(mdl_pain_lat.Coefficients(3,1)),table2array(mdl_pain_lat.Coefficients(3,2))); plaErr = [pla95(1)  abs(diff(pla95([1 2]))) abs(diff(pla95([1 3])))];
plc95 = ExpCalc95fromSE(table2array(mdl_pain_lat.Coefficients(4,1)),table2array(mdl_pain_lat.Coefficients(4,2))); plcErr = [plc95(1)  abs(diff(plc95([1 2]))) abs(diff(plc95([1 3])))];
plcd95 = ExpCalc95fromSE(table2array(mdl_pain_lat.Coefficients(5,1)),table2array(mdl_pain_lat.Coefficients(5,2))); plcdErr = [plcd95(1)  abs(diff(plcd95([1 2]))) abs(diff(plcd95([1 3])))];

ex95 = ExpCalc95fromSE(table2array(mdl_active.Coefficients(2,1)),table2array(mdl_active.Coefficients(2,2))); exErr = [ex95(1)  abs(diff(ex95([1 2]))) abs(diff(ex95([1 3])))];
val95 = ExpCalc95fromSE(table2array(mdl_valsalva.Coefficients(2,1)),table2array(mdl_valsalva.Coefficients(2,2))); valErr = [val95(1)  abs(diff(val95([1 2]))) abs(diff(val95([1 3])))];
posS95 = ExpCalc95fromSE(table2array(mdl_position.Coefficients(2,1)),table2array(mdl_position.Coefficients(2,2))); posSErr = [posS95(1)  abs(diff(posS95([1 2]))) abs(diff(posS95([1 3])))];
posL95 = ExpCalc95fromSE(table2array(mdl_position.Coefficients(3,1)),table2array(mdl_position.Coefficients(3,2))); posLErr = [posL95(1)  abs(diff(posL95([1 2]))) abs(diff(posL95([1 3])))];
posB95 = ExpCalc95fromSE(table2array(mdl_position.Coefficients(4,1)),table2array(mdl_position.Coefficients(4,2))); posBErr = [posB95(1)  abs(diff(posB95([1 2]))) abs(diff(posB95([1 3])))];

pres95 = ExpCalc95fromSE(table2array(mdl_pressure.Coefficients(2,1)),table2array(mdl_pressure.Coefficients(2,2))); presErr = [pres95(1)  abs(diff(pres95([1 2]))) abs(diff(pres95([1 3])))];
puls95 = ExpCalc95fromSE(table2array(mdl_pulsate.Coefficients(2,1)),table2array(mdl_pulsate.Coefficients(2,2))); pulsErr = [puls95(1)  abs(diff(puls95([1 2]))) abs(diff(puls95([1 3])))];
neur95 = ExpCalc95fromSE(table2array(mdl_neuralgia.Coefficients(2,1)),table2array(mdl_neuralgia.Coefficients(2,2))); neurErr = [neur95(1)  abs(diff(neur95([1 2]))) abs(diff(neur95([1 3])))];

lh95 = ExpCalc95fromSE(table2array(mdl_lighthead.Coefficients(2,1)),table2array(mdl_lighthead.Coefficients(2,2))); lhErr = [lh95(1)  abs(diff(lh95([1 2]))) abs(diff(lh95([1 3])))];
spin95 = ExpCalc95fromSE(table2array(mdl_spinning.Coefficients(2,1)),table2array(mdl_spinning.Coefficients(2,2))); spinErr = [spin95(1)  abs(diff(spin95([1 2]))) abs(diff(spin95([1 3])))];
bal95 = ExpCalc95fromSE(table2array(mdl_balance.Coefficients(2,1)),table2array(mdl_balance.Coefficients(2,2))); balErr = [bal95(1)  abs(diff(bal95([1 2]))) abs(diff(bal95([1 3])))];
ring95 = ExpCalc95fromSE(table2array(mdl_ringing.Coefficients(2,1)),table2array(mdl_ringing.Coefficients(2,2))); ringErr = [ring95(1)  abs(diff(ring95([1 2]))) abs(diff(ring95([1 3])))];
th95 = ExpCalc95fromSE(table2array(mdl_thinking.Coefficients(2,1)),table2array(mdl_thinking.Coefficients(2,2))); thErr = [th95(1)  abs(diff(th95([1 2]))) abs(diff(th95([1 3])))];
blur95 = ExpCalc95fromSE(table2array(mdl_blurry.Coefficients(2,1)),table2array(mdl_blurry.Coefficients(2,2))); blurErr = [blur95(1)  abs(diff(blur95([1 2]))) abs(diff(blur95([1 3])))];
sens95 = ExpCalc95fromSE(table2array(mdl_sensory.Coefficients(2,1)),table2array(mdl_sensory.Coefficients(2,2))); sensErr = [sens95(1)  abs(diff(sens95([1 2]))) abs(diff(sens95([1 3])))];
tu95 = ExpCalc95fromSE(table2array(mdl_tingling.Coefficients(2,1)),table2array(mdl_tingling.Coefficients(2,2))); tuErr = [tu95(1)  abs(diff(tu95([1 2]))) abs(diff(tu95([1 3])))];
tb95 = ExpCalc95fromSE(table2array(mdl_tingling.Coefficients(3,1)),table2array(mdl_tingling.Coefficients(3,2))); tbErr = [tb95(1)  abs(diff(tb95([1 2]))) abs(diff(tb95([1 3])))];
tbo95 = ExpCalc95fromSE(table2array(mdl_tingling.Coefficients(4,1)),table2array(mdl_tingling.Coefficients(4,2))); tboErr = [tbo95(1)  abs(diff(tbo95([1 2]))) abs(diff(tbo95([1 3])))];

tth95 = ExpCalc95fromSE(table2array(mdl_dx.Coefficients(2,1)),table2array(mdl_dx.Coefficients(2,2))); tthErr = [tth95(1)  abs(diff(tth95([1 2]))) abs(diff(tth95([1 3])))];
tac95 = ExpCalc95fromSE(table2array(mdl_dx.Coefficients(3,1)),table2array(mdl_dx.Coefficients(3,2))); tacErr = [tac95(1)  abs(diff(tac95([1 2]))) abs(diff(tac95([1 3])))];
ndph95 = ExpCalc95fromSE(table2array(mdl_dx.Coefficients(4,1)),table2array(mdl_dx.Coefficients(4,2))); ndphErr = [ndph95(1)  abs(diff(ndph95([1 2]))) abs(diff(ndph95([1 3])))];
pth95 = ExpCalc95fromSE(table2array(mdl_dx.Coefficients(5,1)),table2array(mdl_dx.Coefficients(2,2))); pthErr = [pth95(1)  abs(diff(pth95([1 2]))) abs(diff(pth95([1 3])))];
oth95 = ExpCalc95fromSE(table2array(mdl_dx.Coefficients(6,1)),table2array(mdl_dx.Coefficients(2,2))); othErr = [oth95(1)  abs(diff(oth95([1 2]))) abs(diff(oth95([1 3])))];
und95 = ExpCalc95fromSE(table2array(mdl_dx.Coefficients(7,1)),table2array(mdl_dx.Coefficients(2,2))); undErr = [und95(1)  abs(diff(und95([1 2]))) abs(diff(und95([1 3])))];

dys95 = ExpCalc95fromSE(table2array(mdl_dysauto.Coefficients(2,1)),table2array(mdl_dysauto.Coefficients(2,2))); dysErr = [dys95(1)  abs(diff(dys95([1 2]))) abs(diff(dys95([1 3])))];
abd95 = ExpCalc95fromSE(table2array(mdl_abd.Coefficients(2,1)),table2array(mdl_abd.Coefficients(2,2))); abdErr = [abd95(1)  abs(diff(abd95([1 2]))) abs(diff(abd95([1 3])))];


x = [abdErr(1) dysErr(1) undErr(1) othErr(1) ndphErr(1) pthErr(1) tacErr(1) tthErr(1) tboErr(1) tbErr(1) tuErr(1) sensErr(1) blurErr(1) thErr(1) ringErr(1) ...
    balErr(1) spinErr(1) lhErr(1) neurErr(1) pulsErr(1) presErr(1) posBErr(1) posSErr(1) posLErr(1) valErr(1) exErr(1) plcdErr(1) plcErr(1) plaErr(1)...
    pluErr(1) freqErr(1) disErr(1) sevErr(1) contErr(1) ethNAErr(1) ethHErr(1) raceUErr(1) raceNAErr(1) raceAErr(1) raceBErr(1) sexErr(1) ageErr(1)];
xneg = [abdErr(2) dysErr(2) undErr(2) othErr(2) ndphErr(2) pthErr(2) tacErr(2) tthErr(2) tboErr(2) tbErr(2) tuErr(2) sensErr(2) blurErr(2) thErr(2) ringErr(2) ...
    balErr(2) spinErr(2) lhErr(2) neurErr(2) pulsErr(2) presErr(2) posBErr(2) posSErr(2) posLErr(2) valErr(2) exErr(2) plcdErr(2) plcErr(2) plaErr(2)...
    pluErr(2) freqErr(2) disErr(2) sevErr(2) contErr(2) ethNAErr(2) ethHErr(2) raceUErr(2) raceNAErr(2) raceAErr(2) raceBErr(2) sexErr(2) ageErr(2)];
xpos = [abdErr(3) dysErr(3) undErr(3) othErr(3) ndphErr(3) pthErr(3) tacErr(3) tthErr(3) tboErr(3) tbErr(3) tuErr(3) sensErr(3) blurErr(3) thErr(3) ringErr(3) ...
    balErr(3) spinErr(3) lhErr(3) neurErr(3) pulsErr(3) presErr(3) posBErr(3) posSErr(3) posLErr(3) valErr(3) exErr(3) plcdErr(3) plcErr(3) plaErr(3)...
    pluErr(3) freqErr(3) disErr(3) sevErr(3) contErr(3) ethNAErr(3) ethHErr(3) raceUErr(3) raceNAErr(3) raceAErr(3) raceBErr(3) sexErr(3) ageErr(3)];

errorbar(x,varNum,[],[],xneg,xpos,'ok','MarkerFaceColor','k')
plot([1 1],[varNum(1) varNum(end)+1],'--k')

subplot(1,3,2)
hold on
title('Full Model')
xlabel('Odds ratio of neck pain')
ax = gca; ax.Box = 'on'; ax.YTick = varNum; ax.YLim = [0 length(varNum)+1]; ax.XScale = 'log'; ax.XLim = [0.1 10]; ax.XTick = [0.1 1 10]; ax.XTickLabels = [0.1 1 10];

varNumFull = fliplr([12 2 6 7 11 10 3 4 13 16 14 15 22:25 17 18 20 19 21 39 38 40 27:32 26 33:35 41 42 44 43 45 46 36 37]);

Err = zeros(length(varNumFull),3);
full_model95 = zeros(length(varNumFull),3);
for x = varNum
    temp = ExpCalc95fromSE(table2array(mdl_Mult.Coefficients(varNumFull(x),1)),table2array(mdl_Mult.Coefficients(varNumFull(x),2)));
    Err(x,:) = [temp(1)  abs(diff(temp([1 2]))) abs(diff(temp([1 3])))];
    full_model95(x,:) = temp;
end
full_model95 = flipud(full_model95);

errorbar(Err(:,1),varNum,[],[],Err(:,2),Err(:,3),'ok','MarkerFaceColor','k')
plot([1 1],[varNum(1) varNum(end)+1],'--k')


subplot(1,3,3)
hold on
title('Final Model')
ax = gca; ax.Box = 'on'; ax.YTick = varNum; ax.YLim = [0 length(varNum)+1]; ax.XScale = 'log'; ax.XLim = [0.1 10]; ax.XTick = [0.1 1 10]; ax.XTickLabels = [0.1 1 10];

varNumFinalCount = [1 9:12 14:16 21:24 26 31 32 34:42];
varNumFinal = fliplr([12 2 6 7 11 10 3 4 13:15 16 18 17 19 28 21:23 20 24:26 27]);

ErrFin = zeros(length(varNumFinal),3);
final_model95 = zeros(length(varNumFinal),3);
for x = 1:length(varNumFinalCount)
    temp = ExpCalc95fromSE(table2array(mdl_MultFinal.Coefficients(varNumFinal(x),1)),table2array(mdl_MultFinal.Coefficients(varNumFinal(x),2)));
    ErrFin(x,:) = [temp(1)  abs(diff(temp([1 2]))) abs(diff(temp([1 3])))];
    final_model95(x,:) = temp;
end
final_model95 = flipud(final_model95);

errorbar(ErrFin(:,1),varNumFinalCount,[],[],ErrFin(:,2),ErrFin(:,3),'ok','MarkerFaceColor','k')
plot([1 1],[varNum(1) varNum(end)+1],'--k')

%% compare those who completed enough of the questionnaire to be included, vs. those who had incomplete information

mdl_incomp = fitglm(comp_incomp,'complete ~ ageY + gender + race + ethnicity','Distribution','binomial');