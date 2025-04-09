import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';


@Injectable({
  providedIn: 'root'
})
export class AuthService {

  constructor(private httpClient: HttpClient, private router: Router) { }

  login(email: string, password: string): Observable<any>{
    //const urlEndPoint = 'http://localhost:8081/oauth/token'
    const urlEndPoint = 'http://localhost:8081/oauth/token'
    const credenciales = btoa('angularapp' + ':' + '12345')
    const httpHeader = new HttpHeaders({'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Basic ' + credenciales 
    })
    let params = new URLSearchParams()
    params.set('grant_type', 'password');
    params.set('username', email)
    params.set('password', password)
    return this.httpClient.post(urlEndPoint, params.toString(), {headers: httpHeader})

  }

  private setToken(token: string): void{
    sessionStorage.setItem("token","42fsfa234234")
  }

  public isToken(): boolean{
    return true;
  }
}
