clc,clear,

global Q;
Q = xlsread('question.xlsx','Sheet4','A1:I9');
Q(isnan(Q)) = 0; % 问题矩阵Q
waitTimeLimit = 10;

global Q;
global A; A = Q; % 答案矩阵A
global answerStack answerPos;
global answerIsFound; answerIsFound = false;
global waitToLong; waitToLong = false;
nextIdx = 1;
while nextIdx < 81 && A(nextIdx) ~= 0
   nextIdx = nextIdx + 1;
end

tic
% 第一次DFS
DFS(nextIdx, [], []);
% 用土办法节约时间，如果耗时超过10秒则转置之后再重新DFS
if waitToLong
    Q=Q'; A=Q;
    answerIsFound = false;
    DFS(nextIdx, [], []);
end

for i = 1:length(answerStack)
    A(answerPos(i)) = answerStack(i);
end
if waitToLong
    Q=Q'; A=A';
end
clc
displaySudoku(A)
toc

%% 深度优先遍历
% 输入节点和已生成的路径，通过examRepeat(M)判断是否走到尽头
% stack记录试过的路径，posInM记录对应在A中的位置
function DFS(nodeIdx, stack, posInM)
    global A Q;
    global answerStack answerPos;
    global answerIsFound waitToLong;
    
    for guess = 1:9
        A(nodeIdx) = guess;

        % 框选待检测行
        toExamRow = A(easyCoord(nodeIdx), :);
        % 框选待检测列
        toExamCol = A(:, ceil(nodeIdx/9));
        % 框选待检测宫
        [r,c] = boxSelect(nodeIdx);
        toExamBox = A(r-2 : r, c-2 : c);

        passRow = examRepeat(toExamRow);
        passCol = examRepeat(toExamCol);
        passBox = examRepeat(toExamBox);

        if passRow && passCol && passBox
            % 三项检测均通过，
            % 则把猜的数字记录到stack，对应的位置记录到posInM，
            % 然后递归

            stack(end+1) = guess;
            posInM(end+1) = nodeIdx;
            nextIdx = nodeIdx + 1;
            % 寻找下一个空位
            while nextIdx < 81 && A(nextIdx) ~= 0
               nextIdx = nextIdx + 1;
            end

            if nextIdx > 81 
                % 若nextIdx超过81，说明已遍历所有格子，
                % 可以输出答案了
                answerStack = stack;
                answerPos = posInM;
                answerIsFound = true;
                break % 时间优化
            else
                % 深度优先遍历：递归！
                DFS(nextIdx, stack, posInM);
                if answerIsFound % 时间优化
                    break
                end
            end
        end
        
    end
    % 当1~9都猜遍了，却没有触发输出答案，说明是死路，
    % 撤回stack与posInM中的上一步记录
    % 以及猜过的9
    if ~answerIsFound % 时间优化
        stack = stack(1:end-1);
        A(nodeIdx) = 0;
        A(posInM(end)) = 0;
        posInM = posInM(1:end-1);
    end

    % 酷炫的解码动画
    if rem(toc,0.05) < 0.001
        clc,
        if ~waitToLong
            displaySudoku(A),
        else
            Q=Q'; A=A';
            displaySudoku(A),
            Q=Q'; A=A';
        end
    end
    % 更新用时，并在超过10秒时中止计算
    % 方法是谎报answerIsFound
    if toc > 10 && ~waitToLong
        answerIsFound = true;
        waitToLong = true;
    end
end

%% 检测宫/行/列是否有重复数字
function result = examRepeat(M)
    result = true;
    % 检测无不是0的重复数字（0代表空位）
    for i = 1:9
        if sum(M==i,"all") > 1
            result = false;
        end
    end
end
%% 生成框选宫的坐标
function [r,c] = boxSelect(idx)

    if idx <= 27
        c = 3;
    elseif idx <= 54
        c = 6;
    elseif idx <= 81
        c = 9;
    end

    switch rem(idx,9)
        case {1,2,3}
            r = 3;
        case {4,5,6}
            r = 6;
        case {7,8,0}
            r = 9;
    end

end
%% 生成行列坐标
function r = easyCoord(idx)
    if rem(idx,9) ~= 0
        r = rem(idx,9);
    else
        r = rem(idx,9)+9;
    end
end

%% 在控制台输出酷炫的过程
function displaySudoku(M)
    global Q;
    for i = 1:9
        line = M(i,:);
        for j = 1:9
            if Q(i,j) ~= 0
                fprintf('%2.i\t', M(i,j))
            elseif M(i,j) ~= 0
                fprintf('[%i]\t', M(i,j))
            else
                fprintf('[ ]\t')
            end
            switch j
                case {3,6}
                    fprintf('\t')
                case {9}
                    fprintf('\n')
            end
        end
        switch i
            case {3,6,9}
                fprintf('\n')
        end
    end
end
