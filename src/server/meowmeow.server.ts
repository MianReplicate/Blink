// by mr sup banana here and this shit took me way to long to setup (fucking help me)

class animal {
    public type = "animal";

    public eat() {

    }

    public makeSound() {
        print("screw you")
    }

}

class dog extends animal {
    public type = "dog";

    public makeSound() {
        super.makeSound();
        print('bark')
    }

    public doLoudSound(){}
}

class cat extends animal {
    public type = "cat"

    public makeSound() {
        print('mew')
    }

    public breakFall(){}
}

let animals = new Array<animal>();
animals.push(new dog());
animals.push(new cat());

for(var animalthing of animals){
    if(animalthing instanceof dog){
        animalthing.doLoudSound()
    }
    if(animalthing instanceof cat){
        animalthing.breakFall()
    }
    print(animalthing.type)
}