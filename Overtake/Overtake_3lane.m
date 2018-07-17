clear
clc
close all
%%
v = 18; L = 4; R_veh = 2.5; deltaSet = linspace(-pi/6, pi/6, 11); 
deltaT = 0.05; Np = 15; res = -2; qc = 0; qp = 10; R_safe = 3; Neigh_dist = 25; 
alpha = 0.3; epsi_rel = 0.01; epsi_abs = 0.03; rho = 1000; max_step = 10000;
tar_dist = 5; replan_dist = 50;
road_width = 10;
%% 创建障碍物，场景，车辆
obstacle = [1, 2; 2, 2; 2, 1; 1, 1];
Campus = Env_con(160, 60, road_width, obstacle, -2);
%% 生成车辆
n = 9; 
veh_group = cell(1,n);
veh1 = veh_con(20, 150, -pi/2, 20, 10, -pi/2, [20, 10, -pi/2], v, L, deltaT, R_veh, R_safe, deltaSet, res, Np, qc, qp, 150);
veh2 = veh_con(20, 150, -pi/2, 20, 10, -pi/2, [20, 10, -pi/2], v-10, L, deltaT, R_veh, R_safe, deltaSet, res, Np, qc, qp, 100);
for i = 1:2
    veh_group{1,i} = eval(['veh',num2str(i)]);
    veh_group{1,i} = Path_ref(veh_group{1,i}, Campus); % Astar生成参考轨迹
end

veh_group{1,3} = veh_group{1,2}; veh_group{1,3}.start_time = 1;
% ================ middle ==================================
veh_group{1,4} = veh_posChange(veh_group{1,1}, 10, 0); veh_group{1,4}.start_time = 90;
veh_group{1,5} = veh_posChange(veh_group{1,1}, 10, 0); veh_group{1,5}.start_time = 120;
veh_group{1,6} = veh_posChange(veh_group{1,3}, 10, 0); veh_group{1,6}.start_time = 50;
% ================ right =========================
veh_group{1,7} = veh_posChange(veh_group{1,1}, 20, 0); veh_group{1,7}.start_time = 170;
veh_group{1,8} = veh_posChange(veh_group{1,2}, 20, 0); veh_group{1,8}.start_time = 100;
veh_group{1,9} = veh_posChange(veh_group{1,3}, 20, 0); veh_group{1,9}.start_time = 20;

real_path = cell(1,n);
for i = 1:n
    real_path{1,i} = [veh_group{1,i}.x_now, veh_group{1,i}.y_now, veh_group{1,i}.theta_now]; % real_path 用途？？
end
%%
tic
time_flag = 0;
while true
    time_flag = time_flag + 1;
    disp(['time_flag = ', num2str(time_flag)]);
    
    for i = 1:n
        veh_group{1,i} = Start_judge_CCA(veh_group{1,i}, time_flag);
        veh_group{1,i} = ADMM_stateUpdate(veh_group{1,i}); 
    end 
    [veh_group, delta_out] = ADMM_CCCP(veh_group, Neigh_dist, rho, max_step, epsi_rel, epsi_abs, obstacle);
    % 状态更新，场景展示
    for i = 1:n
        veh_group{1,i} = veh_struct_model(veh_group{1,i}, delta_out(i,1));
    end
    Env_con_CCA_show(Campus, veh_group, 3.4/3.4);
    % 终止判断
    terminal_tag = 0;
    for i = 1:n
        [veh_group{1,i}, terminal_tag] = Termi_judge_CCA(veh_group{1,i}, tar_dist, replan_dist, Np, terminal_tag);
    end
    disp(terminal_tag);
    if terminal_tag == n
        break
    end
    
end
toc
%%

