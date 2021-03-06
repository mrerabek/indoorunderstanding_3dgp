%   The algorithms implemented by Alexander Vezhnevets aka Vezhnick
%   <a>href="mailto:vezhnick@gmail.com">vezhnick@gmail.com</a>
%
%   Copyright (C) 2005, Vezhnevets Alexander
%   vezhnick@gmail.com
%   
%   This file is part of GML Matlab Toolbox
%   For conditions of distribution and use, see the accompanying License.txt file.
%
%   RealAdaBoost Implements boosting process based on "Real AdaBoost"
%   algorithm
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
%    [Learners, Weights, final_hyp] = RealAdaBoost(WeakLrn, Data, Labels,
%    Max_Iter, OldW, OldLrn, final_hyp)
%    ---------------------------------------------------------------------------------
%    Arguments:
%           WeakLrn   - weak learner
%           Data      - training data. Should be DxN matrix, where D is the
%                       dimensionality of data, and N is the number of
%                       training samples.
%           Labels    - training labels. Should be 1xN matrix, where N is
%                       the number of training samples.
%           Max_Iter  - number of iterations
%           OldW      - weights of already built commitee (used for training 
%                       of already built commitee)
%           OldLrn    - learnenrs of already built commitee (used for training 
%                       of already built commitee)
%           final_hyp - output for training data of already built commitee 
%                       (used to speed up training of already built commitee)
%    Return:
%           Learners  - cell array of constructed learners 
%           Weights   - weights of learners
%           final_hyp - output for training data

function [Learners, Weights, final_hyp] = GentleAdaBoostM(WeakLrn, Data, Labels, Max_Iter, NumClasses)

if( nargin == 5)
  Learners = {};
  Weights = zeros(NumClasses,2*Max_Iter);
%   distr = ones(1,size(Data,2));
%   L1=find(Labels>0);
%   distr(L1)=distr(L1)/(2*length(L1));
%   L2=find(Labels<0);
%   distr(L2)=distr(L2)/(2*length(L2));
  distr = ones(NumClasses, size(Data,2));
  for(i=1:NumClasses)
      x=ones(1,size(Data,2));
      L1=find(Labels==i);
      x(L1)=x(L1)/(2*length(L1));
      L1=find(Labels~=i);
      x(L1)=x(L1)/(2*length(L1));
      distr(i,:)=x;
  end
else
  error('Function takes 5 arguments');
end

curlabels=zeros(size(Labels));

for j=1:NumClasses
  indices(j).i=find(Labels==j);
  Z(j).z=-ones(1,size(Data,2));
  Z(j).z(indices(j).i)=1;
end
a=zeros(2*(2^NumClasses-2),NumClasses);

for It = 1 : Max_Iter
    It
    for n=1:2^NumClasses-2
        binstr=dec2bin(n,NumClasses);
        for j=1:NumClasses
          membership(j)=bin2dec(binstr(j));
          curlabels(indices(j).i)=2*membership(j)-1;
        end
        
        stumps(n).s = train(WeakLrn, Data, curlabels, sum(distr)/sum(sum(distr))*2);
        for i=1:2
            step_out{i}=calc_output(stumps(n).s{i},Data);
            s1=0;
            s2=0;
            for j=1:NumClasses
                if(membership(j))
                    s1=sum((Z(j).z==1).*step_out{i}.*distr(j,:))+s1;
                    s2=sum((Z(j).z==-1).*step_out{i}.*distr(j,:))+s2;
                end
            end
            if(s1==0 && s2==0)
                continue;
            end
            for j=1:NumClasses
                if(membership(j))
                    a(n*2+i-2,j)=(s1-s2)/(s1+s2);
                else
                    a(n*2+i-2,j)=sum(distr(j,:).*Z(j).z)/sum(distr(j,:));
                end
            end
        end
        J(n)=0;
        for j=1:NumClasses
            err=(Z(j).z-a(n*2-1,j)*step_out{1}-a(n*2,j)*step_out{2}).^2;
            J(n)=J(n)+sum(distr(j,:).*err);
        end
    end
    minindx=find(J==min(J));
    minindx=minindx(1);
    Learners{end+1}=stumps(minindx).s{1};
    Learners{end+1}=stumps(minindx).s{2};
    
    step_out{1}=calc_output(stumps(minindx).s{1},Data);
    step_out{2}=calc_output(stumps(minindx).s{2},Data);
    for j=1:NumClasses
        Weights(j,It*2-1)=a(minindx*2-1,j);
        Weights(j,It*2)=a(minindx*2,j);
        hm = Weights(j,It*2-1)*step_out{1}+Weights(j,It*2)*step_out{2};
        distr(j,:)=distr(j,:).*exp(-Z(j).z.*hm);
        distr(j,:)=distr(j,:)/(sum(distr(j,:))*2);
    end
end
