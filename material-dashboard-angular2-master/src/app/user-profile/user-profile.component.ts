import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormControl, Validators } from '@angular/forms';
import { UserService } from 'app/core/services/user.service';

@Component({
  selector: 'app-user-profile',
  templateUrl: './user-profile.component.html',
  styleUrls: ['./user-profile.component.css']
})
export class UserProfileComponent implements OnInit {

  checkoutForm;
  data;
  currency = new Intl.NumberFormat('USD',{
    style: 'currency',
    minimumFractionDigits: 2,
    currency: "USD"
  })

  constructor(private userService: UserService, private formBuilder: FormBuilder) {

    this.checkoutForm = this.formBuilder.group({
      
      email: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),

      fistName: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])), 

      lastName: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])), 

      city: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])),

      country: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])), 

      postal: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])), 

      aboutme: new FormControl('',Validators.compose([
        Validators.required,
        Validators.minLength(4),
        Validators.maxLength(30)      
      ])), 

    });

    this.getUserData()
    
  }

  ngOnInit() {}

  public getUserData() {
    const userData =  JSON.parse(localStorage.getItem("profile"))
    this.userService.getUser(userData.email).subscribe(
      response => {
        this.data = response
        this.loadData(response)
      },
      error => {
        console.log("Error --> ", error)
      }
    )
  }

  loadData(data: any){
    this.checkoutForm.controls['email'].setValue(data.email)
    this.checkoutForm.controls['fistName'].setValue(data.fistName)
    this.checkoutForm.controls['lastName'].setValue(data.lastName)
    this.checkoutForm.controls['city'].setValue(data.city)
    this.checkoutForm.controls['country'].setValue(data.country)
    this.checkoutForm.controls['postal'].setValue(data.postal)
    this.checkoutForm.controls['aboutme'].setValue(data.aboutme)
  }

}
