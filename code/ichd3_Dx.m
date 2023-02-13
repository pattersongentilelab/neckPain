% Determines ICHD3 diagnoses based on patient questionnaire
function [ICHD3] = ichd3_Dx(tbl)
        
%% Migraine features
        
        
        ICHD3 = tbl(:,1);
        
        ICHD3.focal = zeros(height(tbl),1);
        ICHD3.focal(tbl.p_location_side___right==1|tbl.p_location_side___left==1) = 1;
        ICHD3.focal(tbl.p_location_area___sides==1|tbl.p_location_area___front==1|...
            tbl.p_location_area___back==1|tbl.p_location_area___around==1|tbl.p_location_area___behind==1 ... 
            |tbl.p_location_area___top==1|tbl.p_location_area___oth==1) = 1;
        
        ICHD3.photophobia = zeros(height(tbl),1);
        ICHD3.photophobia(tbl.p_assoc_sx_oth_sx___light==1|tbl.p_trigger___light==1) = 1;
        
        ICHD3.phonophobia = zeros(height(tbl),1);
        ICHD3.phonophobia(tbl.p_assoc_sx_oth_sx___sound==1|tbl.p_trigger___noises==1) = 1;
        
        ICHD3.nausea_vomiting(tbl.p_assoc_sx_gi___naus==1|tbl.p_assoc_sx_gi___vomiting==1) = 1;
        
        ICHD3.mig_sev = zeros(height(tbl),1);
        ICHD3.mig_sev(tbl.p_sev_overall=='mod'|tbl.p_sev_usual>3) = 1;
        
        
        ICHD3.mig_char = zeros(height(tbl),1);
        ICHD3.mig_char(ICHD3.focal==1) = ICHD3.mig_char(ICHD3.focal==1)+1;
        ICHD3.mig_char(tbl.pulsate==1) = ICHD3.mig_char(tbl.pulsate==1)+1;
        ICHD3.mig_char(ICHD3.mig_sev==1) = ICHD3.mig_char(ICHD3.mig_sev==1)+1;
        ICHD3.mig_char(tbl.p_trigger___exercise==1|tbl.p_activity=='feel_worse') = ICHD3.mig_char(tbl.p_trigger___exercise==1|tbl.p_activity=='feel_worse')+1;
        
        ICHD3.mig_dur = zeros(height(tbl),1);
        ICHD3.mig_dur(tbl.p_sev_dur=='3days'|tbl.p_sev_dur=='1to3d'|tbl.p_sev_dur=='hrs') = 1;
        
        ICHD3.mig_num = zeros(height(tbl),1);
        ICHD3.mig_num(tbl.p_ha_in_lifetime=='many') = 1;
        
        % determine migraine score, 4 is migraine, 3 is probable migraine
        ICHD3.mig_score = zeros(height(tbl),1);
        
        photophono = sum([ICHD3.photophobia ICHD3.phonophobia],2);
        
        for x=1:height(tbl)
             if ICHD3.mig_num(x)==1 % criteria A of migraine ICHD3
                ICHD3.mig_score(x) = ICHD3.mig_score(x)+1;
             end
            if ICHD3.mig_dur(x)==1 % criteria B of migraine ICHD3
                ICHD3.mig_score(x) = ICHD3.mig_score(x)+1;
            end
            if ICHD3.mig_char(x)>=2 % criteria C of migraine ICHD3
                ICHD3.mig_score(x) = ICHD3.mig_score(x)+1;
            end
            
            if photophono(x)==2 || ICHD3.nausea_vomiting(x)==1 % criteria D of migraine ICHD3
                ICHD3.mig_score(x) = ICHD3.mig_score(x)+1;
            end
        end
        
        
        ICHD3.aura_vis = zeros(height(tbl),1);
        ICHD3.aura_vis (tbl.p_assoc_sx_vis___spot==1|tbl.p_assoc_sx_vis___star==1|tbl.p_assoc_sx_vis___light==1|...
            tbl.p_assoc_sx_vis___zigzag==1|tbl.p_assoc_sx_vis___heat==1|tbl.p_assoc_sx_vis___loss_vis==1) = 1;
        
        ICHD3.aura_sens = zeros(height(tbl),1);
        ICHD3.aura_sens(tbl.p_assoc_sx_neur_uni___numb==1|tbl.p_assoc_sx_neur_uni___tingle==1) = 1;
        
        ICHD3.aura_speech = zeros(height(tbl),1);
        ICHD3.aura_speech(tbl.p_assoc_sx_oth_sx___talk==1) = 1;
        
        ICHD3.aura_weak = zeros(height(tbl),1);
        ICHD3.aura_weak(tbl.p_assoc_sx_neur_uni___weak==1) = 1;
        
        ICHD3.aura = zeros(height(tbl),1);
        ICHD3.aura(ICHD3.aura_sens==1|ICHD3.aura_vis==1|ICHD3.aura_speech==1|ICHD3.aura_weak==1) = 1;
 

        ICHD3.migraine = zeros(height(tbl),1);
        ICHD3.migraine(ICHD3.mig_score==4) = 1;
        
        ICHD3.probable_migraine = zeros(height(tbl),1);
        ICHD3.probable_migraine(ICHD3.mig_score==3) = 1;
        
        ICHD3.migraine_aura = zeros(height(tbl),1);
        ICHD3.migraine_aura(ICHD3.migraine==1 & ICHD3.aura==1) = 1;
        
        ICHD3.chronic_migraine = zeros(height(tbl),1);
        ICHD3.chronic_migraine((ICHD3.migraine==1) & (tbl.p_fre_bad=='2to3wk'|tbl.p_fre_bad=='3wk'|tbl.p_fre_bad=='daily'|tbl.p_fre_bad=='always')) = 1;
        
        ICHD3.chronic_probable_migraine = zeros(height(tbl),1);
        ICHD3.chronic_probable_migraine(ICHD3.probable_migraine==1 & (tbl.p_fre_bad=='2to3wk'|tbl.p_fre_bad=='3wk'|tbl.p_fre_bad=='daily'|tbl.p_fre_bad=='always')) = 1;
        
        ICHD3.probable_migraine_aura = zeros(height(tbl),1);
        ICHD3.probable_migraine_aura(ICHD3.probable_migraine==1 & ICHD3.aura==1) = 1;
 
        %% Tension type headache features
        
        ICHD3.tth_dur(tbl.p_sev_dur=='3days'|tbl.p_sev_dur=='1to3d'|tbl.p_sev_dur=='hrs'|tbl.p_sev_dur=='mins') = 1;
        
         ICHD3.tth_char = zeros(height(tbl),1);
        
        for x=1:height(tbl)
            if tbl.p_location_side___both(x)==1
                ICHD3.tth_char(x) = ICHD3.tth_char(x)+1;
            end
            if tbl.pressure(x)==1
                ICHD3.tth_char(x) = ICHD3.tth_char(x)+1;
            end
            if tbl.p_sev_overall(x)=='mild'||tbl.p_sev_overall(x)=='mod'||tbl.p_sev_usual(x)<7
                ICHD3.tth_char(x) = ICHD3.tth_char(x)+1;
            end
            if tbl.p_trigger___exercise(x)==0 && (tbl.p_activity(x)=='feel_better'||tbl.p_activity(x)=='no_change')
                ICHD3.tth_char(x) = ICHD3.tth_char(x)+1;
            end
        end
        
        % determine if tension-type headache
        ICHD3.tth_score = zeros(height(tbl),1);
        
        for x=1:height(tbl)
             if ICHD3.mig_num(x)==1 % criteria A of tth ICHD3
                ICHD3.tth_score(x) = ICHD3.tth_score(x)+1;
             end
            if ICHD3.tth_dur(x)==1 % criteria B of tth ICHD3 of headache lasting 30 min to days
                ICHD3.tth_score(x) = ICHD3.tth_score(x)+1;
            end
            if ICHD3.tth_char(x)>=2 % criteria C of tth ICHD3
                ICHD3.tth_score(x) = ICHD3.tth_score(x)+1;
            end
            if photophono(x)<2 && ICHD3.nausea_vomiting(x)==0 % criteria D
                ICHD3.tth_score(x) = ICHD3.tth_score(x)+1;
            end
        end
        
        ICHD3.tth = zeros(height(tbl),1);
        ICHD3.tth(ICHD3.tth_score==4) = 1;
        
        %% TAC
        
        ICHD3.unilateral_sideLocked = zeros(height(tbl),1);        
        ICHD3.unilateral_sideLocked(sum(table2array(tbl(:,[136 137])),2)==1) = 1; % can also have bilateral headache

        % unilateral autonomic features
        ICHD3.unilateral_autonomic = zeros(height(tbl),1);
        ICHD3.unilateral_autonomic(tbl.p_assoc_sx_neur_bil___red_eye==0 & tbl.p_assoc_sx_neur_uni___red_eye==1) = 1;
        ICHD3.unilateral_autonomic(tbl.p_assoc_sx_neur_bil___tear==0 & tbl.p_assoc_sx_neur_uni___tear==1) = 1;
        ICHD3.unilateral_autonomic(tbl.p_assoc_sx_neur_bil___run_nose==0 & tbl.p_assoc_sx_neur_uni___run_nose==1) = 1;
        ICHD3.unilateral_autonomic(tbl.p_assoc_sx_neur_bil___puff_eye==0 & tbl.p_assoc_sx_neur_uni___puff_eye==1) = 1;
        ICHD3.unilateral_autonomic(tbl.p_assoc_sx_neur_bil___sweat==0 & tbl.p_assoc_sx_neur_uni___sweat==1) = 1;
        ICHD3.unilateral_autonomic(tbl.p_assoc_sx_neur_bil___flush==0 & tbl.p_assoc_sx_neur_uni___flush==1) = 1;
        ICHD3.unilateral_autonomic(tbl.p_assoc_sx_neur_bil___full_ear==0 & tbl.p_assoc_sx_neur_uni___full_ear==1) = 1;
        ICHD3.unilateral_autonomic(tbl.p_assoc_sx_neur_bil___ptosis==0 & tbl.p_assoc_sx_neur_uni___ptosis==1) = 1;
        ICHD3.unilateral_autonomic(tbl.p_assoc_sx_neur_uni___pupilbig==1) = 1;
        
        % bilateral autonomic features
        ICHD3.bilateral_autonomic = zeros(height(tbl),1);
        ICHD3.bilateral_autonomic(tbl.p_assoc_sx_neur_bil___red_eye==1 & tbl.p_assoc_sx_neur_uni___red_eye==0) = 1;
        ICHD3.bilateral_autonomic(tbl.p_assoc_sx_neur_bil___tear==1 & tbl.p_assoc_sx_neur_uni___tear==0) = 1;
        ICHD3.bilateral_autonomic(tbl.p_assoc_sx_neur_bil___run_nose==1 & tbl.p_assoc_sx_neur_uni___run_nose==0) = 1;
        ICHD3.bilateral_autonomic(tbl.p_assoc_sx_neur_bil___puff_eye==1 & tbl.p_assoc_sx_neur_uni___puff_eye==0) = 1;
        ICHD3.bilateral_autonomic(tbl.p_assoc_sx_neur_bil___sweat==1 & tbl.p_assoc_sx_neur_uni___sweat==0) = 1;
        ICHD3.bilateral_autonomic(tbl.p_assoc_sx_neur_bil___flush==1 & tbl.p_assoc_sx_neur_uni___flush==0) = 1;
        ICHD3.bilateral_autonomic(tbl.p_assoc_sx_neur_bil___full_ear==1 & tbl.p_assoc_sx_neur_uni___full_ear==0) = 1;
        ICHD3.bilateral_autonomic(tbl.p_assoc_sx_neur_bil___ptosis==1 & tbl.p_assoc_sx_neur_uni___ptosis==0) = 1;
        
        % any duration because this does not specify based on which tac
        
        ICHD3.tac = zeros(height(tbl),1);
        ICHD3.tac(ICHD3.unilateral_sideLocked==1 & ICHD3.unilateral_autonomic==1) = 1;

        %% Primary stabbing headache
        ICHD3.psh_score = zeros(height(tbl),1);
        
        for x=1:height(tbl)
            if tbl.p_ha_quality___stab(x)==1||tbl.p_ha_quality___sharp(x)==1 % criteria A, stabbing pain
                ICHD3.psh_score(x) = ICHD3.psh_score(x)+1;
            end
            if tbl.p_sev_dur(x)=='secs' % criteria B of, duration of seconds
                ICHD3.psh_score(x) = ICHD3.psh_score(x)+1;
            end
            if ICHD3.unilateral_autonomic(x)==1 || tbl.p_activity(x)=='move' % criteria D, no autonomic features; C (recur with irregular frequency) we cannot easily measure
                ICHD3.psh_score(x) = ICHD3.psh_score(x)+1;
            end
        end
        
        ICHD3.psh = zeros(height(tbl),1);
        ICHD3.psh(ICHD3.psh_score==3) = 1;

        
        %% Determine if headache meets criteria for PTH or NDPH/new onset headache
        
        
        ICHD3.pth = zeros(height(tbl),1);
        ICHD3.pth(tbl.p_epi_prec___conc==1|tbl.p_con_st_epi_prec_ep___conc) = 1;
        
        ICHD3.ndph_newonset = zeros(height(tbl),1);
        ICHD3.ndph_newonset(~isnat(tbl.p_con_start_date)) = 1;
        
        %% final diagnosis
        
        ICHD3.dx = zeros(height(tbl),1);
        ICHD3.dx(ICHD3.tth==1) = 3;
        ICHD3.dx(ICHD3.probable_migraine==1) = 2;
        ICHD3.dx(ICHD3.migraine==1) = 1;
        ICHD3.dx(ICHD3.tac==1) = 4;
        ICHD3.dx(ICHD3.ndph_newonset==1) = 5;
        ICHD3.dx(ICHD3.pth==1) = 6;
        
        
        ICHD3.dx = categorical(ICHD3.dx,[0 1 2 3 4 5 6],{'other','migraine','prob_migraine','tth','tac','ndph_no','pth'});
        
end