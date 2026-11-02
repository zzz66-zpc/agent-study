height = float(input("请输入你的身高（米）："))
weight = float(input("请输入你的体重（公斤）："))
bmi = weight/(height**2)
print(f"你的 BMI 是:{bmi:.1f}")
if bmi<18.5:
    print("判断:偏瘦 ")
    print("建议:需要注意饮食和营养")
elif bmi<24:
    print("判断:正常 ")
    print("建议:注意保持良好的生活习惯")
elif bmi<28:
    print("判断:超重 ")
    print("建议:需要注意饮食和运动")
else:
    print("判断:肥胖 ")
    print("建议:需要控制饮食并且保持良好的作息")
