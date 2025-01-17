classdef settings_utils
    %SETTINGS_UTILS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        
        %% bv or bv+cell
        model;
        
        %% geometry
        discretize;
        
        %% static flow calculation
        userdefined_qin; % flow input
        pbc; % pressure and flow bc
        
        %% flow input bc's
        qin;
        %% dynamic parameters
        
        % # species
        NVs; %NVs =  No. of transport species in vessel
        Vspecies;
        NCs;
        Cspecies;
        Vinf;
        rxn_set;
        rxn_vol;
        
        %parameters
        diffusivity;
       
        pressure_scan;
        glucose_scan;
        
        % speed up
        jpattern_set; %odeset
        jacobian_set; %odeset     
        saveop_4julia;
        
    end
    
    methods
        
        %% ---------------------------------------------------------------------------------------
        %% graph_utils settings
        %% ---------------------------------------------------------------------------------------
        
        function obj = setting
            I = INI('File','input.ini');
            I.read();
            data = I.get('UserData'); % struct
            obj.test_graph = data.test_graph;
            obj.run = data.run;
            obj.pbc = data.pbc;
            obj.discretize = data.discretize;
            obj.userdefined_qin = data.userdefined_qin;
            obj.qin = data.qin;
            obj.model = data.model;
            obj.NVs = data.NVs;
            obj.IC_Vspecies = data.IC_Vspecies;
            obj.Vinf = data.Vinf;
            obj.IC_Cspecies = data.IC_Cspecies;
            obj.rxn_set = data.rxn_set;
            obj.rxn_vol = data.rxn_vol;
        end
        
        function test_graph = select_graph
            test_graph = struct(...
            'test1',false,...
            'test2',false,...
            'test3',false,...
            'test4',false,...
            'test6',false,...
            'test7',false,...
            'test8',false,...    % test2a of comsol
            'test9',false,...   % design 1 tumor chen2020: outlet close to inlet
            'test10',false,...   % design 2 tumor chen2020: outlet away from inlet
            'test11',true,...   % islet chen2020
            'test12',false,...   % islet chen2020 3x replica
            'test13',false,...   % islet chen2020 4x replica
            'test11x',false,...  % islet chen2020 5x replica
            'test15',false,...   % islet chen2020 6x replica
            'test16',false,...   % islet chen2020 7x replica
            'test17',false,...  % islet chen2020 edge attack (7,14)
            'test20',false,...  % erlich2019
            'test21',false,...   % mesen90 secomb 913 segments data
            'test24',false...    % esposito secomb 913 segments data
        );
        end

%         function test_graph = select_graph(graph)
%           obsolete

%           persistent Var;
%           if nargin
%             Var = graph;
%           end
%           test_graph = Var;
%         end
  
        function run = run_set
            % tc = time course
            % ps = parameter gscan
            % pscan = pressure scan
            % gscan = glucose scan
            % ascan = attack scan (robustness analysis)
            
           tspan   = 0:0.0001:0.25; % 0:0.001:.25; %0:.01:5 % test11
%             tspan = [0:0.01:2, 2.01:0.1:5]; % for creating animation of test24 
%             tspan   = [0:0.005:0.2, 0.21:0.05:0.8, 0.81:2.5:50];%[0:3:50, 50:150:3000]; % for creating animation of test9/10
        	run = struct('single', true, ...
        	             'gscan', false, ...
        	             'pscan', false, ...
        	             'ascan', false, ...
        	             'tspan', tspan, ...
        	             'tend', tspan(end) ...
        	             );
        end
        
        function pbc = pbc_set
            
            pbc_case = struct(...
                        'pbc1',false,... % Pin, Pout   
                        'pbc2',true,... % Pin, outflow % test9/10/11
                        'pbc3',false...  % inflow, Pout % test24
                        ); 
            F           = fieldnames(pbc_case);
            pbc          = F(cell2mat(struct2cell(pbc_case)));
            pbc          = pbc{1};
        end
        
         function discretize = get_discretize_status
            discretize = false;
         end
        
         function userdefined_qin = get_userdefined_qin_status 
            userdefined_qin = false;
         end
        
        function qin = get_qin
            % qin : inflow set by the user
            % for default-values set userdefined_qin = true in line 27
            qin = 1E+6; % 1nl/min (=1e+6 um^3/min)
        end
        
%         function mesh_type = get_mesh_type
%             mesh_type = struct('uniform', false);
%         end
        
        %% ---------------------------------------------------------------------------------------
        %% model_utils settings
        %% ---------------------------------------------------------------------------------------
        
        function model = run_model 
            model = struct('vessel', true);
        end
        
        
        % NVs =  No. of transport species in vessel
        function NVs = get_NVspecies
%             % one : simulate the first species in list VSpecies 
%             N = struct("one", true, "two", false);
%             if N.one == true
%                 NVs = 1;
%             elseif N.two == true
%                 NVs = 2;
%             else
%                 NVs = 4; %length(settings_utils.get_Vspecies);
%             end
            NVs = 1;
        end
        
        % IC_Vspecies IC of vessel species
        % IC_Cspecies IC of cell species
        function IC_Vspecies = get_IC_Vspecies
            IC_Vspecies = struct('glc_ext', 5, 'lac_ext', 1.2, 'ins_ext', 1.7, 'cpep_ext', 1.7); %lac_ext: 1.2
        end
        
        function Vinf = get_Vinf
            Vinf = struct('glc_ext', 8, 'lac_ext', 3, 'ins_ext', 0, 'cpep_ext', 0); % lac_ext: 3
        end
        
        function IC_Cspecies = get_IC_Cspecies
            IC_Cspecies = struct('glc', 0, 'lac',0); 
        end
        
        function rxn_set = get_rxn_set
            % degree_2 = true % all nodes that have degree = 2 = rxn_node
            % degree_2 = false % read from input file
            % input will be read from file for test6.
            rxn_set = struct('degree_2',true);
        end
        
        %% ---------------------------------------------------------------------------------------
        %% simulation settings
        %% ---------------------------------------------------------------------------------------

        function rxn_vol  = get_rxn_vol_set
            % equal = cell volume = blood vessel volume
            rxn_vol  = struct('equal',  false);
        end 
       
        function transporter = get_transporter
            transporter.glc_ext = struct('Vm', 100, 'Km', 1.0);
            transporter.lac_ext = struct('Vm', 100, 'Km', 0.5);
        end
        
        % VSpecies = list of transport species in blood vessel
        % CSpecies = list of species in cell
        
        function Vspecies = get_Vspecies
            Vspecies = ["glc_ext", "lac_ext", "ins_ext", "cpep_ext"];
            Vspecies = Vspecies(1:settings_utils.NVs);
        end
        
         % NCs =  No. of reaction species in cell
        function NCs = get_NCspecies
            NCs = length(settings_utils.get_Cspecies);
        end
        
        function CSpecies = get_Cspecies
            CSpecies = ["glc", "lac"];
        end
                        
        function diffusivity = get_diffusivity

            % properties of chemical species
            % chalhoub2006
            % Diffusivity of glucose in blood =5.46E-4 cm2/min
            % Diifusivity of lactate in blood =7.71E-4 cm2/min

            diffusivity = struct('glc_ext', 5.46E4, 'lac_ext',7.71E4, 'ins_ext', 9.6E3, 'cpep_ext', 9.6E3); % units in um^2/min
        end

        
        function glc_ext = get_glucose_scan
            glc_ext = 2:0.5:20; 
        end
            
        function pressure_scan = get_pressure_scan
            % mmHg to Pa = 133.322
            % pressure_scan = 133.322*[0.001 0.1 1 10 100 200]; %20 30 40 %scan1 
            % pressure_scan = 133.322*[0.001 0.01 0.1 0.5 0.8 1 2 3 4 5 10 20 30 40]; % 100 200]; % default
            pressure_scan = 20:20:200; %[20 40 60 80 10l0 120 140 160 180 200];
        end
        
        function jpattern_set = get_jpattern_set
            jpattern_set = false; %odeset
        end
        
        function jacobian_set = get_jacobian_set
            jacobian_set = false; %odeset     
        end
        
        function saveop_4julia = get_saveop_4julia_status
            saveop_4julia =  false;
        end
         
    end 
end

