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
data_comp.anxdepBin = data_comp.anxdep2;
data_comp.anxdepBin(data_comp.anxdepBin>0) = 1;

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
ICHD3.dx = reordercats(ICHD3.dx,{'migraine','chronic_migraine','prob_migraine','tth','chronic_tth','tac','new_onset','ndph','pth','other_primary','undefined'});
ICHD3.dx = mergecats(ICHD3.dx,{'tth','chronic_tth'});
ICHD3.dx = mergecats(ICHD3.dx,{'ndph','new_onset'});
ICHD3.dx = mergecats(ICHD3.dx,{'migraine','chronic_migraine','prob_migraine'});
data_comp.ichd3 = ICHD3.dx;

%% Univariate analysis
% predictor variable: presence of anxiety and/or depression
[pAgeAnx,tblAgeAnx,statsAgeAnx] = kruskalwallis(data_comp.ageY,data_comp.anxdep);
[tblSexAnx,ChiSexAnx,pSexAnx] = crosstab(data_comp.gender,data_comp.anxdep);
[tblRaceAnx,ChiRaceAnx,pRaceAnx] = crosstab(data_comp.race,data_comp.anxdep);
[tblEthAnx,ChiEthAnx,pEthAnx] = crosstab(data_comp.ethnicity,data_comp.anxdep);
[tblBHanx,ChiBHanx,pBHanx] = crosstab(data_comp.bh_provider,data_comp.anxdep);
[pSevAnx,tblSevAnx,statsSevAnx] = kruskalwallis(data_comp.severity_grade,data_comp.anxdep);
[pFreqAnx,tblFreqAnx,statsFreqAnx] = kruskalwallis(data_comp.freq_bad,data_comp.anxdep);
[pPMAnx,tblPMAnx,statsPMAnx] = kruskalwallis(data_comp.p_pedmidas_score,data_comp.anxdep);
[tblDCanx,ChiDCanx,pDCanx] = crosstab(data_comp.dailycont,data_comp.anxdep);
[pTrigAnx,tblTrigAnx,statsTrigAnx] = kruskalwallis(data_comp.triggerN,data_comp.anxdep);
[pASxAnx,tblASxAnx,statsASxAnx] = kruskalwallis(data_comp.assocSxN,data_comp.anxdep);
[tblICHDanx,ChiICHDanx,pICHDanx] = crosstab(data_comp.ichd3,data_comp.anxdep);

% Outcome variable
mdl_pedmidasSex = fitlm(data_comp,'p_pedmidas_score ~ gender','RobustOpts','on');
PM_sex95 = [Calc95fromSE(table2array(mdl_pedmidasSex.Coefficients(2,1)),table2array(mdl_pedmidasSex.Coefficients(2,2))) table2array(mdl_pedmidasSex.Coefficients(2,4))];

mdl_pedmidasAge = fitlm(data_comp,'p_pedmidas_score ~ age','RobustOpts','on');
PM_age95 = [Calc95fromSE(table2array(mdl_pedmidasAge.Coefficients(2,1)),table2array(mdl_pedmidasAge.Coefficients(2,2))) table2array(mdl_pedmidasAge.Coefficients(2,4))];

mdl_pedmidasRace = fitlm(data_comp,'p_pedmidas_score ~ race','RobustOpts','on');
PM_race95(1,:) = [Calc95fromSE(table2array(mdl_pedmidasRace.Coefficients(2,1)),table2array(mdl_pedmidasRace.Coefficients(2,2))) table2array(mdl_pedmidasRace.Coefficients(2,4))];
PM_race95(2,:) = [Calc95fromSE(table2array(mdl_pedmidasRace.Coefficients(3,1)),table2array(mdl_pedmidasRace.Coefficients(3,2))) table2array(mdl_pedmidasRace.Coefficients(3,4))];
PM_race95(3,:) = [Calc95fromSE(table2array(mdl_pedmidasRace.Coefficients(4,1)),table2array(mdl_pedmidasRace.Coefficients(4,2))) table2array(mdl_pedmidasRace.Coefficients(4,4))];
PM_race95(4,:) = [Calc95fromSE(table2array(mdl_pedmidasRace.Coefficients(5,1)),table2array(mdl_pedmidasRace.Coefficients(5,2))) table2array(mdl_pedmidasRace.Coefficients(5,4))];
PM_race95(5,:) = [Calc95fromSE(table2array(mdl_pedmidasRace.Coefficients(6,1)),table2array(mdl_pedmidasRace.Coefficients(6,2))) table2array(mdl_pedmidasRace.Coefficients(6,4))];
PM_race95(6,:) = [Calc95fromSE(table2array(mdl_pedmidasRace.Coefficients(7,1)),table2array(mdl_pedmidasRace.Coefficients(7,2))) table2array(mdl_pedmidasRace.Coefficients(7,4))];

mdl_pedmidasEthnicity = fitlm(data_comp,'p_pedmidas_score ~ ethnicity','RobustOpts','on');
PM_eth95(1,:) = [Calc95fromSE(table2array(mdl_pedmidasEthnicity.Coefficients(2,1)),table2array(mdl_pedmidasEthnicity.Coefficients(2,2))) table2array(mdl_pedmidasEthnicity.Coefficients(2,4))];
PM_eth95(2,:) = [Calc95fromSE(table2array(mdl_pedmidasEthnicity.Coefficients(3,1)),table2array(mdl_pedmidasEthnicity.Coefficients(3,2))) table2array(mdl_pedmidasEthnicity.Coefficients(3,4))];
PM_eth95(3,:) = [Calc95fromSE(table2array(mdl_pedmidasEthnicity.Coefficients(4,1)),table2array(mdl_pedmidasEthnicity.Coefficients(4,2))) table2array(mdl_pedmidasEthnicity.Coefficients(4,4))];

mdl_pedmidasCont = fitlm(data_comp,'p_pedmidas_score ~ dailycont','RobustOpts','on');
PM_cont95 = [Calc95fromSE(table2array(mdl_pedmidasCont.Coefficients(2,1)),table2array(mdl_pedmidasCont.Coefficients(2,2))) table2array(mdl_pedmidasCont.Coefficients(2,4))];

mdl_pedmidasBH = fitlm(data_comp,'p_pedmidas_score ~ bh_provider','RobustOpts','on');
PM_bh95 = [Calc95fromSE(table2array(mdl_pedmidasBH.Coefficients(2,1)),table2array(mdl_pedmidasBH.Coefficients(2,2))) table2array(mdl_pedmidasBH.Coefficients(2,4))];

mdl_pedmidasAD = fitlm(data_comp,'p_pedmidas_score ~ anxdep','RobustOpts','on');
PM_ad95(1,:) = [Calc95fromSE(table2array(mdl_pedmidasAD.Coefficients(2,1)),table2array(mdl_pedmidasAD.Coefficients(2,2))) table2array(mdl_pedmidasAD.Coefficients(2,4))];
PM_ad95(2,:) = [Calc95fromSE(table2array(mdl_pedmidasAD.Coefficients(3,1)),table2array(mdl_pedmidasAD.Coefficients(3,2))) table2array(mdl_pedmidasAD.Coefficients(3,4))];
PM_ad95(3,:) = [Calc95fromSE(table2array(mdl_pedmidasAD.Coefficients(4,1)),table2array(mdl_pedmidasAD.Coefficients(4,2))) table2array(mdl_pedmidasAD.Coefficients(4,4))];

mdl_pedmidasFreq = fitlm(data_comp,'p_pedmidas_score ~ freq_bad','RobustOpts','on');
PM_freq95 = [Calc95fromSE(table2array(mdl_pedmidasFreq.Coefficients(2,1)),table2array(mdl_pedmidasFreq.Coefficients(2,2))) table2array(mdl_pedmidasFreq.Coefficients(2,4))];

mdl_pedmidasSev = fitlm(data_comp,'p_pedmidas_score ~ severity_grade','RobustOpts','on');
PM_sev95 = [Calc95fromSE(table2array(mdl_pedmidasSev.Coefficients(2,1)),table2array(mdl_pedmidasSev.Coefficients(2,2))) table2array(mdl_pedmidasSev.Coefficients(2,4))];

mdl_pedmidasTrig = fitlm(data_comp,'p_pedmidas_score ~ triggerN','RobustOpts','on');
PM_trig95 = [Calc95fromSE(table2array(mdl_pedmidasTrig.Coefficients(2,1)),table2array(mdl_pedmidasTrig.Coefficients(2,2))) table2array(mdl_pedmidasTrig.Coefficients(2,4))];

mdl_pedmidasSx = fitlm(data_comp,'p_pedmidas_score ~ assocSxN','RobustOpts','on');
PM_sx95 = [Calc95fromSE(table2array(mdl_pedmidasSx.Coefficients(2,1)),table2array(mdl_pedmidasSx.Coefficients(2,2))) table2array(mdl_pedmidasSx.Coefficients(2,4))];

mdl_pedmidasICHD = fitlm(data_comp,'p_pedmidas_score ~ ichd3','RobustOpts','on');
PM_ichd95(1,:) = [Calc95fromSE(table2array(mdl_pedmidasICHD.Coefficients(2,1)),table2array(mdl_pedmidasICHD.Coefficients(2,2))) table2array(mdl_pedmidasICHD.Coefficients(2,4))];
PM_ichd95(2,:) = [Calc95fromSE(table2array(mdl_pedmidasICHD.Coefficients(3,1)),table2array(mdl_pedmidasICHD.Coefficients(3,2))) table2array(mdl_pedmidasICHD.Coefficients(3,4))];
PM_ichd95(3,:) = [Calc95fromSE(table2array(mdl_pedmidasICHD.Coefficients(4,1)),table2array(mdl_pedmidasICHD.Coefficients(4,2))) table2array(mdl_pedmidasICHD.Coefficients(4,4))];
PM_ichd95(4,:) = [Calc95fromSE(table2array(mdl_pedmidasICHD.Coefficients(5,1)),table2array(mdl_pedmidasICHD.Coefficients(5,2))) table2array(mdl_pedmidasICHD.Coefficients(5,4))];
PM_ichd95(5,:) = [Calc95fromSE(table2array(mdl_pedmidasICHD.Coefficients(6,1)),table2array(mdl_pedmidasICHD.Coefficients(6,2))) table2array(mdl_pedmidasICHD.Coefficients(6,4))];
PM_ichd95(6,:) = [Calc95fromSE(table2array(mdl_pedmidasICHD.Coefficients(7,1)),table2array(mdl_pedmidasICHD.Coefficients(7,2))) table2array(mdl_pedmidasICHD.Coefficients(7,4))];

% multiple regression analysis
mdl_Mdisability = fitlm(data_comp,'p_pedmidas_score ~ gender + ageY + race + ethnicity + anxdep + bh_provider + dailycont + freq_bad + severity_grade + triggerN + assocSxN + ichd3','RobustOpts','on');

tbl_95CI = table(mdl_Mdisability.CoefficientNames','VariableNames',{'Name'});
tbl_95CI.estimate = zeros(height(tbl_95CI),1);
tbl_95CI.low95 = zeros(height(tbl_95CI),1);
tbl_95CI.hi95 = zeros(height(tbl_95CI),1);
tbl_95CI.p_val = zeros(height(tbl_95CI),1);

for x = 1:mdl_Mdisability.NumCoefficients
    temp = Calc95fromSE(table2array(mdl_Mdisability.Coefficients(x,1)),table2array(mdl_Mdisability.Coefficients(x,2)));
    tbl_95CI.estimate(x) = temp(1);
    tbl_95CI.low95(x) = temp(2);
    tbl_95CI.hi95(x) = temp(3);
    tbl_95CI.p_val(x) = table2array(mdl_Mdisability.Coefficients(x,4));
end



%% compare those who completed enough of the questionnaire to be included, vs. those who had incomplete information

mdl_incomp = fitglm(comp_incomp,'complete ~ ageY + gender + race + ethnicity','Distribution','binomial');

%% plot regression analysis (final model and full model are the same because all variables were either significant or included a priori)

varNum = 1:1:height(tbl_95CI);
tbl_95CI = flipud(tbl_95CI);

figure
hold on
errorbar(tbl_95CI.estimate(1:end-1),varNum(1:end-1),[],[],abs(diff([tbl_95CI.estimate(1:end-1) tbl_95CI.low95(1:end-1)],[],2)),abs(diff([tbl_95CI.estimate(1:end-1) tbl_95CI.hi95(1:end-1)],[],2)),'ok','MarkerFaceColor','k')
plot([0 0],[varNum(1) varNum(end)],'--k')
title('Full and Final Model')
xlabel('Predicted change in PedMIDAS score')
ax = gca; ax.Box = 'on'; ax.YTick = varNum(1:end-1); ax.YTickLabels = tbl_95CI.Name(1:end-1); ax.YLim = [0 length(varNum)+1]; ax.XLim = [-20 20]; ax.XTick = -50:10:50;

