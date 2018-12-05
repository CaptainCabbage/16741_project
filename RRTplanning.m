function [T_   , isfound, goal_path] = RRTplanning(Xstart, Xgoal, env, object, friction_coeff, maxIter, thr)
    % T: tree of RTT planning
    % Xstart: start configuration of object, [x,y,theta]
    % Xgoal: goal configuration of object, only [theta]
    % maxIter: maximum iteration number
    % thr: the threshold allow for Xgoal
    %
    sample_env = [0+12,0+12;20,0+12;20,20;0+12,20]';
    isfound = 0;
    end_ind = 0;
    goal_path = [];
    [isStartCollide,start_contacts] = CollisionDetectionV2(env, object, Xstart);
    if isStartCollide 
        error('start configuration collided!');
    end
    if isempty(start_contacts)
        error('The object is floating :-) ');
    end
    %Start to construct RTT tree
    T = RRTtree(Xstart, start_contacts, []);
    % sample start configuration stable finger contacts
    start_fingers = cell(10,1);
    for finger_sample = 1:20
        theta = Xstart(3);
        R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
        start_contacts_o(1:2, :) = R'*start_contacts(1:2, :);
        start_contacts_o(3:4, :) = R'*(start_contacts(3:4,:)- Xstart(1:2));
        [fp1, fn1] = randomSampleContact(object, start_contacts_o);
        [fp2, fn2] = randomSampleContact(object, start_contacts_o);
        start_fingers{finger_sample} = [fn1,fn2;fp1,fp2];
    end
    %start_fingers{1} = [-1,0,12,0;1,0,-12,0]';
    start_fingers{1} = [-1,0,12,0;0,-1,0,12]';
    start_fingers{2} = [0,1,12,-12;0,-1,0,12]';

    for i = 1:maxIter
        [Xclosest_ind, cur_dist] = T.nearestNeighbor(Xgoal);
        if cur_dist < thr % TODO: check if goal is reached
            isfound = 1;
            end_ind = Xclosest_ind;
            break;
        end
%         randomly sample to maintain at least one contact constraint
        if mod(i,2) == 1
            Xrand = Xgoal;
        else 
            Xrand = RandomSampleObjectConfig(sample_env); % TODO: sample from random state,50% from the goal stat
        end
        [Xnear_ind, ~] = T.nearestNeighbor(Xrand); 
        Xnear = [T.vertex(Xnear_ind).x, T.vertex(Xnear_ind).y, T.vertex(Xnear_ind).theta]';
        
        % in extend, to maintain at least one env contact constraints
        %if numel(Xrand) == 1
        %   Xnew = extend([Xnear(1:2);Xrand], Xnear,T.vertex(Xnear_ind).env_contacts);
        %else
        %Xnew = extend(Xrand, Xnear,T.vertex(Xnear_ind).env_contacts);
            %Xnew_start = extend(Xrand, Xstart,T.vertex(1).env_contacts); 
        %end
        Xnew_set = enumerateContactModeMotion2(Xrand, Xnear, env,T.vertex(Xnear_ind).env_contacts);
        for xnew_ind = 1:numel(Xnew_set)
            Xnew = Xnew_set{xnew_ind};
            [isXnewCollide,Xnew_env_contacts] = CollisionDetectionV2(env, object, Xnew);

            dx = Xnew-Xnear;
            twist = [dx(3),dx(1),dx(2)]';
            if ~isXnewCollide && norm(twist)~=0
                if Xnear_ind==1
                   for k = 1:numel(start_fingers)
                    [isXnewMotion, Xnew_finger_contacts] = isStableMotionAllowed(twist, Xnew_env_contacts, ...
                        object,T.vertex(1).env_contacts,start_fingers{k}, Xstart, [Xstart(1:2);0;1], friction_coeff); 
                    if isXnewMotion
                        T = T.add_node(1, Xnew, Xnew_env_contacts, Xnew_finger_contacts);
                        break
                    end
                   end
                else        
                    [isXnewMotion, Xnew_finger_contacts] = isStableMotionAllowed(twist, Xnew_env_contacts, ...
                        object,T.vertex(Xnear_ind).env_contacts,T.vertex(Xnear_ind).finger_contacts, Xnear, [Xnear(1:2);0;1], friction_coeff); 
                    if isXnewMotion
                        T = T.add_node(Xnear_ind, Xnew, Xnew_env_contacts, Xnew_finger_contacts);
                    end
                end
            end
          % if Xnew collide, look at the start
%                 Xnew_start = extend(Xrand, Xstart,T.vertex(1).env_contacts);
%                 [isXnewstartCollide,Xnewstart_env_contacts] = CollisionDetectionV2(env, object, Xnew_start);
%                 if ~isXnewstartCollide && norm(Xnew_start - Xstart)~=0
%                     dx = Xnew_start-Xstart;
%                     twist = [dx(3),dx(1),dx(2)]';
%                     for k = 1:20%numel(start_fingers)
%                         [fp1, fn1] = randomSampleContact(object, start_contacts_o);
%                         [fp2, fn2] = randomSampleContact(object, start_contacts_o);
%                         new_fingers = [fn1,fn2;fp1,fp2];
%                         [isXnewstartMotion, Xnewstart_finger_contacts] = isStableMotionAllowed(twist, Xnewstart_env_contacts, ...
%                             object,T.vertex(1).env_contacts,new_fingers , Xstart, [Xstart(1:2);0;1], friction_coeff); 
%                         if isXnewstartMotion
%                             T = T.add_node(1, Xnew_start, Xnewstart_env_contacts, Xnewstart_finger_contacts);
%                             break
%                         end
%                     end
%                 end
          end
    end

%         if ~isXnewstartCollide
%             dx = Xnew_start-Xstart;
%             twist = [dx(3),dx(1),dx(2)]';
%             for k = 1:numel(start_fingers)
%                 [isXnewstartMotion, Xnewstart_finger_contacts] = isStableMotionAllowed(twist, Xnewstart_env_contacts, ...
%                     object,T.vertex(1).env_contacts,start_fingers{k}, Xstart, [Xstart(1:2);0;1], friction_coeff); 
%                 if isXnewstartMotion
%                     T = T.add_node(1, Xnew_start, Xnewstart_env_contacts, Xnewstart_finger_contacts);
%                     break
%                 end
%             end
%         end     
        % combining adding vertex and edge
    if i == maxIter
        fprintf('max RRT iteration reached')
    end
    if end_ind ~= 0
        % display states and fingers
        goal_path = T.get_path(end_ind);
        T_ = T;
        fprintf('goal state motions found')
    else
        T_ = T;
        [Xclosest_ind, ~] = T.nearestNeighbor(Xgoal);
        goal_path = T.get_path(Xclosest_ind);
        fprintf('no state close enough to goal state\n');
    end
end