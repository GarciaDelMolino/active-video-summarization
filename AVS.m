%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      Active Video Summarization                         %
%                            v1.0 - May 2017                              %
%                                                                         %
%            Ana Garcia del Molino (stugdma@i2r.a-star.edu.sg)            %
%                                                                         %
%                                                                         %
%   This script executes the AVS system with its GUI as described in:     %
%                                                                       
% Active Video Summarization: Customized Summaries via On-line Interaction with the User.
% Ana Garcia del Molino, Xavier Boix, Joo-Hwee Lim, Ah-Hwee Tan
% In AAAI Conference on Artificial Intelligence, North America, feb. 2017. 
% Available at: <https://www.aaai.org/ocs/index.php/AAAI/AAAI17/paper/view/14856>
%                                                                       
%                                                                         %
%      This algorithm has been tested in Windous and Unix machines.       %
%       It has been licensed under the GNU General Public License.        %
%    If you use this software for research purposes, you should cite      %
%        the aforementioned paper in any resulting publication.           %
%                                                                         %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                       path and figure set-up                          %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all

if 0 %using_windows
    code_mrf='MRF_win';
else %using_unix
    code_mrf='MRF_Unix';       
end    
data_root='CSumm'; 
objects_dir=[data_root '/parent_child.mat'];
places_dir=[data_root '/categories.mat'];
data_root='/media/ana/My Book/Lifelogging/TESTING';

addpath(genpath(code_mrf))  
addpath(genpath('aux_functions'))  


% To store the previously asked questions:
storing=0;
if storing 
    if exist('questions','dir')  
        files=dir('questions/*.png'); 
    else
        mkdir('questions')
        files=dir('questions/*.png');
    end
    files=arrayfun(@(i) ['questions/' files(i).name],1:length(files),'UniformOutput',0);
    if ~isempty(files)
        delete(files{:});
    end
end

%Only the first time using AVS: extract images from the videos
error(sprintf('\nACTION FOR USER!!:\n\nRemove this error message to extract the frames for CSumm dataset in Unix.\nYou can open several MATLAB labs for a faster extraction. Once the frames have been extracted, set this condition to false.\n\nIf using Windows, we recommend using avconv on "Bash on Ubuntu on Windows"'))    
if true
cd(data_root)
extract_frames
cd('../')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                             get inputs                                %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Select the video to summarize
load directory.mat
vid=listdlg('PromptString','Select a video:',...%'ListSize',[200 300],
    'ListString',cellfun(@(i) [sorted_home{set_d(i(1)),1} '_' sorted_home{set_d(i(1)),3}],u_study(1:17,2),'UniformOutput',0));
v_id=set_d(u_study{vid,2});


%Load features
if ~exist(sprintf('data%d.mat',vid),'file')
    
home=sorted_home(v_id,1);
home=cellfun(@(i) [data_root, i(2:end)],home,'UniformOutput',0);
b0=batch('descriptor'); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                   other config and variables                          %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
param=struct('max',4,'min',3,'config',5,'cij',100,'cji',50,...
    'ci',0.9,'pi',1,'ki',5,'l',0.2,'pji',5,'kij',-1,'kji',0.5,...
    'l_big',[],'l_small',0, 'pi_big',[],'pi_small',0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                    extract or load features                           %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load descriptor, batch just after selecting video:
fprintf('Extracting ... ')
wait(b0) 
fprintf('Done extracting features\n')
load(b0, 'desc', 'init', 'q','illumination', 'motion','frames','animals','objects','places');
delete(b0);
clear b0

w=[];

%segmentation:
b1=batch('segmentation'); 

%labels for passive preferences
b2=batch('passive');
clear animals objects places

% load segmentation:
fprintf('Segmenting ... ')
wait(b1) 
fprintf('Done segmentation\n')
load(b1, 'boundaries', 'desc_seg', 'q_seg');
delete(b1);

clear q motion illumination desc b1


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                 setup for passive preferences                         %%    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%load labels for passive preferences
wait(b2) 
load(b2, 'passive_pref','la');
delete(b2);
clear b2

save(sprintf('data%d.mat',vid))

else 
    fprintf('loading workspace ... ')
    load(sprintf('data%d.mat',vid))
    fprintf('Done\n')
end
 
% clustering for inference, init parameters crf (pairwise)
b3=batch('init_crf');     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                  input parameters, start GUI                          %%        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
aux = inputdlg({'Min length:', 'Max length:'},'Enter the length (in segments)',...
1,{num2str(max(3,ceil(length(u_study{vid,2})))),num2str(max(4,ceil(length(u_study{vid,2})*1.4)))});
param.min=str2double(aux{1});
param.max=str2double(aux{2});

user_id=str2double(inputdlg('User ID:','Enter the user id',1,{'0'}));
task=0;

%Open figure:
clear ctrl f
f=openfig('AVS.fig');
ctrl=guihandles(f);
axis(ctrl.video,'off');
set(ctrl.summary,'Visible','off')
set(ctrl.segment,'Visible','off')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                   segment importance/quality                          %%        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

node=((q_seg./repmat(max(1,max(q_seg)),[length(q_seg),1]))*[0.75; 0.25])'; 

if 1 %Selecting passive preferences
% Ask for passive preferences, "node" is modified accordingly, where passive_pref is a binary
% vector with ones in the selected features: 
selectiony=listdlg('PromptString','Select relevant items:',...%'ListSize',[200 300],
    'ListString',[{'none'};passive_pref]);
selectionn=listdlg('PromptString','Select irelevant items:',...%'ListSize',[200 300],
    'ListString',[{'none'};passive_pref]);

passive_pref=zeros(1,size(desc_seg,2));
if selectiony~=1, passive_pref(la(selectiony-1))=1; end
if selectionn~=1, passive_pref(la(selectionn-1))=passive_pref(la(selectionn-1))-1; end
prefs=(1+max(1*passive_pref*desc_seg',-1)); 

if size(desc_seg,1)>600
    prune=find(node>prctile(node,30));
    param.cji=max(5,100/(1.5*2^(ceil(length(prune)/500)))); 
else
    prune=1:length(node);
end

clear passive_pref selectiony selectionn labels
end

param.ci=param.ci/max(node.*prefs);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                          Active preferences                           %%         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
finish_now=0;

%---------------------------------------------------%
%                   Init potentials                 %
prm=param;
user=struct('want',[],'no_want',[],'indiferent',[],'bring_w',[],'bring_nw',[],'order',[]);
lcl=[ones(size(node)); (param.ci*node.*prefs).^param.ki]; 

%load CRF setup
wait(b3) 
load(b3, 'segments','d','cnn','cnnd','cnnp','param');
delete(b3);

fprintf('Done with CRF init.\n')
adapting=1;
summ=0;
tt=tic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                 Initial Summary Inference                     %%         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sum_evolution=[];
sum_changes=[];
total_time=[];
clicks=[];

tic;
[summ,prob,param,~]=compute_summ(param,node,cnn,user,1,d,80,prefs,prune,lcl,summ); 
sum_evolution=[sum_evolution, prob(1:end,2)];
sum_changes=[sum_changes, logical(summ(1:end-1))];
total_time=[total_time toc(tt)];
seg=segments;
re_query=0;
seg_q=[];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                      Active Inference                         %%         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while ~get(ctrl.finish,'Value')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                Infer next Q while showing vid                   %         
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if ~re_query
    if (length(user.want)<param.max)
        
        %estimate new Q in batch
        la=cellfun(@(n) randperm(length(n)),seg(1,:),'UniformOutput',0);
        %I don't want to ask again same subshot (in this batch of questions) if user said "irrelevant": 
        e=cellfun(@(i) isempty(i),seg(1,:));
        qs=cellfun(@(n,l) n(l(1)),seg(1,~e),la(~e));
        
        
        % prob wanting similars and prob wanting candidate:
        prob_q=arrayfun(@(i) unique([cnn(2,(cnn(1,:)==i)),cnn(1,(cnn(2,:)==i))]),...
            qs,'UniformOutput',0);            
        prob_q=cell2mat(cellfun(@(l) [max(prob(l,2)) min(prob(l,1)) max(prob(l,2)) min(prob(l,1))],...
            prob_q','UniformOutput',0)).*[prob(qs,2) prob(qs,2) prob(qs,1) prob(qs,1)];%,'descend');

        b1=batch('what_to_query');

        fr=frames(cell2mat(arrayfun(@(j,k) j:(k-1),boundaries(find(summ==1)),...
            boundaries(min(find(summ==1)+1,length(boundaries))),'UniformOutput',0)'),1);
        set(ctrl.summary,'Visible','on')
        set(ctrl.segment,'Visible','off')
        set(ctrl.eval_seg,'Visible','off')
        paralel_batch=1;
        movie_show
        paralel_batch=0;
        
    else
        set(ctrl.eval_seg,'Visible','off')
        set(ctrl.segment,'Visible','off')
        set(ctrl.summary,'Visible','on')
            %-----------------------------------------------------------%
            %if summ = max, then inform the user he cannot chose any more 
            %segment. He must remove one from the summary, or end.
            %Alternatively, he can ask for the facilitator help to add an
            %extra segment (param.max=param.max+1).
        resp=questdlg(sprintf('Choose to add one more segment or go to the summary to modify its segments.\n(Alternatively, close the window to go back to the GUI).'),sprintf('You''ve reached the maximum length (%d segments).',param.max), 'Add one more', 'Go to Summary','Go to Summary');
        if strcmp(resp,'Add one more')
            param.max=param.max+1;
            set(ctrl.eval_seg,'Value',1)
        elseif strcmp(resp, 'Go to Summary')
            set(ctrl.eval_summ,'Value',1)
        end
        
        while ~get(ctrl.eval_seg,'Value')&&~get(ctrl.eval_summ,'Value')&&~get(ctrl.finish,'Value')&&~get(ctrl.seg_next,'Value')
        pause(0.5)
        end
    end

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%       User chooses to eval summ, new segment, or finish        %         
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if get(ctrl.finish,'Value')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                         Finish                    % 
        if  strcmp('Yes',questdlg('Are you sure you want this summary as the final one?','','Yes','No','No'))
            finish_now=1;    
            %Adapt user to whatever is in the final video:
            s=find(summ==1)';
            s=s(~ismember(s,user.want)); 
            user.want=[user.want s];
            user.bring_w=[user.bring_w cell(1,length(s))];
            user.order=[user.order ones(1,length(s))];
            user.bring_nw(ismember(user.no_want,s))=[];  
            user.no_want(ismember(user.no_want,s))=[];
            break
        end
        set(ctrl.finish,'Value',0)
        while ~get(ctrl.eval_seg,'Value')&&~get(ctrl.eval_summ,'Value')&&~get(ctrl.finish,'Value')
            pause(0.1)
        end
    end
    end
    
    evaluating_final=0;
    if ~get(ctrl.eval_seg,'Value')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                   Evaluate Summary                %   
        new_segment=0;
        seg=segments;
        set(ctrl.eval_summ,'Value',0)
        clicks=[clicks false];
        s=find(summ==1)';
        s=s(~ismember(s,[user.want, user.no_want]));  
        if isempty(s)
            s=find(summ==1)';
            evaluating_final=1;
            user2=user;
        end

    else    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                   Evaluate Segment                % 
        new_segment=1;
        set(ctrl.eval_seg,'Value',0)
        if ~re_query
        if ~strcmp(b1.State,'finished')
            msgbox('Please wait for the system to find a new segment','Computation in progress')
        end
        wait(b1) 
        load(b1, 'improv', 'dif', 'params', 'probs');
        delete(b1);
        
        %resize to original size of segment:
        prob_q2=prob_q;
        prob_q(~e,:)=prob_q;
        prob_q(e,:)=0;
        improv(~e,:)=improv;
        improv(e,:)={0};
        dif(~e,:)=dif;
        dif(e,:)=0;
        params(~e,:)=params;
        params(e,:)={0};
        probs(~e,:)=probs;
        probs(e,:)={0};        
        end
        
        set(ctrl.summary,'Visible','off')

        try
            s=sum(dif.*prob_q,2);
            s=find(s==max(s));
        catch
            aux=zeros(length(e),1);
            aux(~e)=prob(qs,2);
            s=median(dif,2).*aux;
            s=find(s==max(median(dif,2).*aux));        
        end
        if isempty(s)||(length(s)>1)                
            s=randsample(find(~e),1);
        end         

        sk=s;
        s=seg{1,sk}(la{sk}(1));
        clicks=[clicks true];
        seg_q=[seg_q s];
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%                 Get feedback from user and update              %         
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~get(ctrl.finish,'Value')
        set(ctrl.segment,'Visible','on')  
        set(ctrl.summary,'Visible','off')
        for p=1:length(s)
            auxw=find(user.want==s(p));
            auxnw=find(user.no_want==s(p));
            
            %set defaults to user previous answer, if existing: 
            if ~isempty(auxw) 
                %This segment had a yes answer
                set(ctrl.seg_yes,'Value',1)
                if isempty(user.bring_w{auxw})
                    set(ctrl.sim_idk,'Value',1)
                else
                    set(ctrl.sim_yes,'Value',user.bring_w{auxw})
                    set(ctrl.sim_no,'Value',~user.bring_w{auxw})
                end
            elseif ~isempty(auxnw) 
                %This segment had a no answer
                set(ctrl.seg_no,'Value',1)
                if isempty(user.bring_nw{auxnw})
                    set(ctrl.sim_idk,'Value',1)
                else
                    set(ctrl.sim_yes,'Value',user.bring_nw{auxnw})
                    set(ctrl.sim_no,'Value',~user.bring_nw{auxnw})
                end
            else
                %This segment is new
                set(ctrl.seg_idk,'Value',1)
                set(ctrl.sim_idk,'Value',1)
            end
            
            %show segment and wait for answer:
            fr=frames(cell2mat(arrayfun(@(j,k) j:(k-1),boundaries(s(p)),...
        boundaries(min(s(p)+1,length(boundaries))),'UniformOutput',0)'),1);
            movie_show
            set(ctrl.seg_next,'Value',0)

            %record answer in user preferences
            if isempty(user.bring_w),  user.bring_w=cell(1);   end
            if isempty(user.bring_nw), user.bring_nw=cell(1);   end

            if get(ctrl.seg_idk,'Value')         
                %remove previous answer if existing
                if ~isempty(auxw)
                user.order(min(find(cumsum(user.order)==auxw)))=[];
                user.bring_w(auxw)=[];
                user.want(auxw)=[];
                elseif ~isempty(auxnw)
                user.order(min(find(cumsum(~user.order)==auxnw)))=[];
                user.bring_nw(auxnw)=[];
                user.no_want(auxnw)=[];                    
                end  
                 
                % since nothing happens, ask next q in qs if new_segment. 
                % Do not show same summary and re-infer next q.
                % DONE at the end of user feedback.
                
            elseif get(ctrl.seg_yes,'Value')
                %remove previous answer if no, record new answer. Also
                %update similars if changed 
                if ~isempty(auxnw) 
                    %This segment had a no answer, remove from user:
                    user.order(min(find(cumsum(~user.order)==auxnw)))=[];
                    user.bring_nw(auxnw)=[];  
                    user.no_want(auxnw)=[];  
                elseif isempty(auxw) 
                    %This is a new segment, include in user:
                    user.order=[user.order, 1];
                    user.want=[user.want, s(p)];
                end
                
                %add answer for 'similars':
                if get(ctrl.sim_idk,'Value')
                    user.bring_w((user.want==s(p)))={[]}; 
                    prob=0;
                else
                    user.bring_w((user.want==s(p)))={get(ctrl.sim_yes,'Value')};
                    if new_segment
                        prob=probs{sk,1+get(ctrl.sim_no,'Value')};    
                        summ=improv{sk,1+get(ctrl.sim_no,'Value')};
                        param=params{sk,1+get(ctrl.sim_no,'Value')};
                        segments{1,sk}(la{sk}(1))=[];
                    end
                end

            elseif get(ctrl.seg_no,'Value')
                %remove previous answer if yes, record new answer. Also
                %update similars if changed                
                if (~isempty(auxw))
                    %This segment had a yes, remove from user:
                    user.order(min(find(cumsum(user.order)==auxw)))=[]; %formulaci�n incorrecta: order contiene want y no want, usar cumsum o algo. min(find(cumsum(user.order)==find(user.want==s(p))))
                    user.bring_w(auxw)=[];
                    user.want(auxw)=[];
                elseif isempty(auxnw) 
                    %This is a new segment, include in user:
                    user.order=[user.order, 0];
                    user.no_want=[user.no_want, s(p)];
                end
                
                %add answer for 'similars':
                if get(ctrl.sim_idk,'Value')
                    user.bring_nw((user.no_want==s(p)))={[]}; 
                    prob=0;
                else
                    user.bring_nw((user.no_want==s(p)))={get(ctrl.sim_yes,'Value')};
                    if new_segment
                        prob=probs{sk,3+get(ctrl.sim_no,'Value')};    
                        summ=improv{sk,3+get(ctrl.sim_no,'Value')};
                        param=params{sk,3+get(ctrl.sim_no,'Value')};  
                        segments{1,sk}(la{sk}(1))=[];
                    end
                end
            end
            if storing, copyfile(frames{boundaries(s(p))},sprintf('questions/Q%d_%d_%d_%d.png',length(clicks),p,get(ctrl.seg_yes,'Value'),get(ctrl.sim_yes,'Value'))); end
            if isempty(user.want),  user.bring_w=[];   end
            if isempty(user.no_want), user.bring_nw=[];   end
        end
               
        if evaluating_final&&(~re_query)
            new=[user.want user.no_want];
            old=[user2.want user2.no_want];

            removed=old(~ismember(old,new));
            %maybe include in best cluster? pdist2(desc_seg(removed),c)? [~,id]=pdist2(double(c),double(removed),'euclidean','Smallest',1);
            id=randperm(size(segments,2),1);
            segments{1,id}=[removed segments{1,id}];

            added=new(~ismember(new,old));
            segments=cellfun(@(i) setdiff(i,added),segments,'UniformOutput',0);

            clear old new removed id added user2
            seg=segments;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %              Generate new summ if prob not available            %         
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ((length(prob)==1)||(~new_segment))
            [summ,prob,param,~]=compute_summ(param,node,cnn,user,1,d,80,prefs,prune,lcl,summ); 
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %  Remove segment from pool & cancel next inference if no change  %         
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        if new_segment
            seg{1,sk}(la{sk}(1))=[]; %I don't want to ask again same subshot (in this batch of questions) if user said "irrelevant"   
            if ~sum(~(sum_changes(:,end)==logical(summ(1:end-1))))                             
               if (sum(~e)<=1) 
                   % no more segments in the pipeline. Restart inference.
                    aux=cellfun(@isempty, segments(1,:));
                    seg(:,aux)=[];
                    segments(:,aux)=[];
                    re_query=0; 
               elseif ~ismember(s,[user.want user.no_want]) %user said idk                  
                   re_query=max(re_query,1);
                   e(sk)=1;
                   dif(sk,:)=0;
                   probs(sk,:)={0}; %all other dif and probs remain same
                   set(ctrl.eval_seg,'Value',1);
                   uiwait(msgbox('You will be shown a new segment.'));
               elseif ismember(s,[user.want user.no_want]) %user said yes/no but no change in summary
                    re_query=max(2,re_query*2);  %if 4, restart inference  
                    if (re_query<4) 
                        %given new answer, probs have changed, even if slightly.
                        %we asume dif does not change; prob_q=prob_q.*new_prob_q;                        
                        probs(:,:)={0}; %we don't know what the new probs may be.
                        qs(~e)=qs;
                        e(sk)=1;
                        qs(e)=0;
                        qs=qs(~e);

                        new_prob_q=arrayfun(@(i) unique([cnn(2,(cnn(1,:)==i)),cnn(1,(cnn(2,:)==i))]),...
                            qs,'UniformOutput',0);  
                        if 1
                        %opA: prob_q=prob_q.*new_prob_q;
                        prob_q=prob_q(~e,:).*cell2mat(cellfun(@(l) [max(prob(l,2)) min(prob(l,1)) max(prob(l,2)) min(prob(l,1))],...
                            new_prob_q','UniformOutput',0)).*[prob(qs,2) prob(qs,2) prob(qs,1) prob(qs,1)];
                        else
                        %opB: prob_q=prob_qs(t-1).*new_prob_q;
                        prob_q=[sum_evolution(qs,end) sum_evolution(qs,end) 1-sum_evolution(qs,end) 1-sum_evolution(qs,end)].*...
                            cell2mat(cellfun(@(l) [max(prob(l,2)) min(prob(l,1)) max(prob(l,2)) min(prob(l,1))],...
                            new_prob_q','UniformOutput',0)).*[prob(qs,2) prob(qs,2) prob(qs,1) prob(qs,1)];
                        end
                        set(ctrl.eval_seg,'Value',1);
                        uiwait(msgbox('You will be shown a new segment.'));
                    else
                        % 2nd time asking to re_query with a yes/no answer
                        aux=cellfun(@isempty, segments(1,:));
                        seg(:,aux)=[];
                        segments(:,aux)=[];
                        re_query=0;   
                        % no need to re-compute summ: it's just been done (prob=0).
                    end
               end
            else %Infer from new batch of segments.
                aux=cellfun(@isempty, segments(1,:));
                seg(:,aux)=[];
                segments(:,aux)=[];
                re_query=0; %In case this comes from previous re_query
            end
        end

        sum_evolution=[sum_evolution, prob(1:end,2)];
        sum_changes=[sum_changes, logical(summ(1:end-1))];
        total_time=[total_time toc(tt)];  
    end
    
         
    
end
 
set(ctrl.finish,'Value',0)
summ(user.no_want)=0;
summ(user.want)=1; 
            
sum_evolution=[sum_evolution, prob(1:end,2)];
sum_changes=[sum_changes, logical(summ(1:end-1))];
total_time=[total_time toc(tt)];

summary_satisfaction=str2num(cell2mat(inputdlg(sprintf('Did the system manage to provide your ideal summary for that video?\n1: Not at all\n2: Not much\n3: So-so\n4: Pretty much\n5: Absolutely'),...
    'Rate the summary', 1)));

final_summary=frames(cell2mat(arrayfun(@(j,k) j:(k-1),boundaries(find(summ==1)),...
        boundaries(min(find(summ==1)+1,length(boundaries))),'UniformOutput',0)'),1);

if task==0
    task_description=inputdlg('Task description:','Enter the task description',1,{'Own'});
end

try
save(sprintf('annotations/video%d_user%d_benchmark%d.mat',vid, user_id, task),...
    'home','total_time','sum_evolution', 'sum_changes', ...
    'summary_satisfaction', 'clicks','final_summary',...
    'user','task','task_description','seg_q');
catch
    mkdir('annotations/')
    save(sprintf('annotations/video%d_user%d_benchmark%d.mat',vid, user_id, task),...
    'home','total_time','sum_evolution', 'sum_changes', ...
    'summary_satisfaction', 'clicks','final_summary',...
    'user','task','task_description','seg_q');
end