class BMI:
    def __init__(self, height: float, weight: float) -> None:
        self.height = height
        self.weight = weight
    def value(self) -> float:
        return self.weight / (self.height ** 2)
    def judge(self) -> tuple:
        bmi = self.value()
        if bmi<18.5:
            return "偏瘦", "需要补充营养。"
        elif bmi<24:
            return "正常", "保持健康的方式。"
        elif bmi<28:
            return "超重", "需要注意饮食和运动。"
        else:
            return "肥胖", "需要加强锻炼和控制饮食。"
    def report(self) -> str:
        label,tip = self.judge()
        return (f"你的 BMI 是：{self.value():.2f}\n"
                f"判断:{label}\n"
                f"建议:{tip}")
def main() -> None:
    try:
        height = float(input("请输入身高（米）："))
        weight = float(input("请输入体重（公斤）："))
    except ValueError:
        print("输入有误：请输入数字，不要留空。")
        return
    if height <= 0 or weight <= 0:
        print("输入有误：身高和体重必须大于零。")
        return
    person = BMI(height,weight)
    print(person.report())
if __name__ =="__main__":
    main()
    