---
title: 算法题丨Longest Consecutive Sequence
tags:
  - 算法
  - 编程技巧
  - 数据结构
categories: 计算机基础
date: 2017-01-03
---
![avatar](/uploads/images/43aa6878-123e-40ae-84c5-ca0e19bee1ae.jpg)
### 描述
>Given an unsorted array of integers, find the length of the longest consecutive elements sequence.
Your algorithm should run in O(n) complexity.

### 示例
 ```
Given [100, 4, 200, 1, 3, 2],
The longest consecutive elements sequence is [1, 2, 3, 4]. Return its length: 4.
 ```
<!-- more -->
### 算法分析
**难度**：高
**分析**：给定未排序的整型数组，找到数值连续的元素，并返回连续元素的最大长度。
**思路**：首先考虑一般的思路，可以将数组先排序，然后遍历数组元素，判断是否连续，返回最大连续元素的个数，这样的话，循环的复杂度为*O* (n)，排序的复杂度为*O* (nlgn)，算法的整体复杂度为*O* (nlgn)，并不满足题目要求的复杂度。所以，该算法题目的难点是如何采用*O* (n)的算法。
再考虑使用哈希表来存储元素，因为哈希表提供了*O* (1)复杂度的Contains方法，以便我们快速的访问元素:
&emsp;1. 首先，我们将数组元素构造成哈希表，并定义变量longestStreak=0，用来记录最大连续元素的个数;
&emsp;2. 遍历哈希表,判断当前元素num-1，是否存在在哈希表中：
&emsp;&emsp;a). 如果不存在，不用处理，继续遍历哈希表下一个元素;
&emsp;&emsp;b). 如果存在，说明有比当前元素小1的值，则定义currentNum=当前元素，定义currentStreak=1，表示currentNum作为开始比较的元素，刚开始的连续元素个数为1；
&emsp;&emsp;c). 开始后续比较，如果哈希表存在currentNum+1的元素，表示当前元素currentNum有后续相邻的元素，连续的元素为之前最大连续元素次数+1，开始下个一个元素比较，即currentNum+1;
&emsp;&emsp;d). 后续比较结束后，将本次循环获得的currentStreak作为本次循环记录的最大连续元素个数，记录本次最大连续次数currentStreak和之前最大连续次数longestStreak的最大值到longestStreak，并进入下一个循环遍历;
&emsp;3. 循环遍历结束后，返回最大连续次数longestStreak;

### 代码示例(C#)
```csharp
public int LongestConsecutive(int[] nums)
{
    var numSet = new HashSet<int>(nums);
    int longestStreak = 0;
    
    foreach (int num in numSet)
    {
        if (!numSet.Contains(num - 1))
        {
            int currentNum = num;
            int currentStreak = 1;

            while (numSet.Contains(currentNum + 1))
            {
                currentNum += 1;
                currentStreak += 1;
            }
            longestStreak = Math.Max(longestStreak, currentStreak);
        }
    }
    return longestStreak;
}                                            
 ```
### 复杂度
- **时间复杂度**：*O* (n). 
- **空间复杂度**：*O* (n).

### 附录
- [系列目录索引](/posts/algorithm/index/)
- [代码实现(C#版)](https://github.com/lizzie2008/LeetCode.git)
