---
title: 算法题丨Two Sum
tags:
  - 算法
  - 编程技巧
  - 数据结构
categories: 计算机基础
date: 2017-01-04
---
![avatar](https://mysite.bj.bcebos.com/images/articles/b4dae30a-2092-401e-b14e-85477d335250.jpg)

### 描述
>Given an array of integers, return indices of the two numbers such that they add up to a specific target.
You may assume that each input would have exactly one solution, and you may not use the same element twice.

### 示例
```
Given nums = [2, 7, 11, 15], target = 9,

Because nums[0] + nums[1] = 2 + 7 = 9,
return [0, 1].
```
<!-- more -->

### 算法分析
**难度**：低
**分析**：要求给定的数组，查找其中2个元素，满足这2个元素的相加等于给定目标target的值。
**思路**：一般的思路，我们遍历数组元素，假设当前遍历的数组元素x，再次遍历x之后的数组元素，假设当前再次遍历的数组元素y，判断x+y是否满足target，如果满足，则返回x,y下标，否则继续遍历，直至循环结束。考虑这种算法的时间复杂度是*O* (n²)，不是最优的解法。
跟前面几章类似，我们可以考虑用哈希表来存储数据，这里用C#提供的Hashtable来存储下标-对应值（key-value）键值对；
接着遍历数组元素，如果目标值-当前元素值存在当前的Hashtable中，则表明找到了满足条件的2个元素，返回对应的下标；
如果Hashtable没有满足的目标值-当前元素值的元素，将当前元素添加到Hashtable，进入下一轮遍历，直到满足上一条的条件。

### 代码示例(C#)
```csharp
public int[] TwoSum(int[] nums, int target)
{
    var map = new Hashtable(); ;
    for (int i = 0; i < nums.Length; i++)
    {
        int complement = target - nums[i];
        //匹配成功，返回结果
        if (map.ContainsKey(complement))
        {
            return new int[] { (int)map[complement], i };
        }
        map.Add(nums[i], i);
    }
    return null;
}                                      
```

### 复杂度
- **时间复杂度**：*O* (n). 
- **空间复杂度**：*O* (1).

### 附录
- [系列目录索引](/posts/algorithm/index/)
- [代码实现(C#版)](https://github.com/lizzie2008/LeetCode.git)
- 相关算法
	- [3Sum](/posts/algorithm/3Sum/)
	- [3Sum Closest](/posts/algorithm/3Sum Closest/)
	- [4Sum](/posts/algorithm/4Sum/)	
