---
title: 算法题库丨RemoveDuplicates II
tags:
  - 算法
  - 编程技巧
  - 数据结构  
categories: 计算机基础
date: 2017-01-02
---
![avatar](/uploads/images/e4ec8743-c64c-4c29-8381-85f8acd01b8c.jpg)
### 描述
>Follow up for "[Remove Duplicates](/posts/algorithm/RemoveDuplicates/)":
What if duplicates are allowed at most twice?

### 示例
 ```
Given sorted array nums = [1,1,1,2,2,3],

Your function should return length = 5, with the first five elements of nums 
being 1, 1, 2, 2 and 3. It doesn't matter what you leave beyond the new length.
 ```
<!-- more -->
### 算法分析
**难度**：中
**分析**：条件参考[Remove Duplicates](/posts/algorithm/RemoveDuplicates/)，只不过之前元素只允许重复1次，现在改为最多可以重复2次。
**思路**：输入的数组任然排好序的，我们定义i,从i=0开始，依次遍历数组中的每个元素：
当i<2时，不管怎样，元素都会满足条件，也就是说，前2条数据总是满足最多重复2次;
当i>2时，比较遍历当前元素数组[i]是否满足大于元素数组[i-2]：
&emsp;1. 如果不满足，i值不变，遍历下个元素;
&emsp;2. 如果满足，把数组[i-2]值赋值给数组[i],数组0-i的元素都为有效值,i自加1;
再次循环判断，一直到数组最后一个元素.

### 代码实例(C#)
```csharp
 public static int RemoveDuplicates2(int[] nums)
 {
     int i = 0;
     foreach (var num in nums)
     {
         if (i < 2 || num > nums[i - 2])
             nums[i++] = num;
     }
     return i;
 }                                             
 ```
### 复杂度
- **时间复杂度**：*O* (n). 
- **空间复杂度**：*O* (1).

### 相关算法
- [Remove Duplicates](/posts/algorithm/RemoveDuplicates/)


