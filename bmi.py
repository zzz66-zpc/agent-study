def calc_bmi(height, weight):
    return weight / (height ** 2)
def judge(bmi):
    if bmi<18.5:
        return"偏瘦"
    elif bmi<24:
        return"正常"
    elif bmi<28:
        return"超重"
    else:
        return"肥胖"
def advice(bmi):
    if bmi<18.5:
        return"补充营养"
    elif bmi<24:
        return"保持健康的方式"
    elif bmi<28:
        return"适当运动，控制饮食"
    else:
        return"加强锻炼，控制饮食"

def main():
    height = float(input("请输入身高（米）："))
    weight = float(input("请输入体重（公斤）："))
    bmi = calc_bmi(height,weight)
    print(f"你的 BMI 是:{bmi:.1f}")
    print(f"判断:{judge(bmi)}")
    print(f"建议:{advice(bmi)}")
if __name__ =="__main__":
        main()
