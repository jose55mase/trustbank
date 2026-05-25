package com.bolsadeideas.springboot.backend.apirest.auth;

import java.util.Arrays;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.config.annotation.web.configuration.EnableResourceServer;
import org.springframework.security.oauth2.config.annotation.web.configuration.ResourceServerConfigurerAdapter;
import org.springframework.security.web.access.intercept.FilterSecurityInterceptor;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

@Configuration
@EnableResourceServer
public class ResourceServerConfig extends ResourceServerConfigurerAdapter {

	@Autowired
	private ModuleAccessFilter moduleAccessFilter;

	@Autowired
	private SupervisorAccessFilter supervisorAccessFilter;

	@Override
	public void configure(HttpSecurity http) throws Exception {
		http.authorizeRequests().antMatchers(HttpMethod.GET, "/api/clientes", "/index" ,"/api/user/uploads/img/**", "/images/**", "/api/health").permitAll()
				.antMatchers(HttpMethod.POST,"/api/user/save", "/api/public/register").permitAll()
				.antMatchers("/h2-console/**").permitAll()

		/*.antMatchers(HttpMethod.GET, "/api/clientes/{id}").hasAnyRole("USER", "ADMIN")
		.antMatchers(HttpMethod.POST, "/api/clientes/upload").hasAnyRole("USER", "ADMIN")
		.antMatchers(HttpMethod.POST, "/api/clientes").hasRole("ADMIN")
		.antMatchers("/api/clientes/**").hasRole("ADMIN")*/
		.anyRequest().authenticated()
		.and().cors().configurationSource(corsConfigurationSource())
		.and().headers().frameOptions().disable()
		.and().addFilterBefore(moduleAccessFilter, FilterSecurityInterceptor.class)
		.addFilterAfter(supervisorAccessFilter, ModuleAccessFilter.class);


	}

	@Bean
	public CorsConfigurationSource corsConfigurationSource() {
		CorsConfiguration config = new CorsConfiguration();
		config.setAllowedOrigins(Arrays.asList("*"));
		config.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
		config.setAllowCredentials(false);
		config.setAllowedHeaders(Arrays.asList("Content-Type", "Authorization", "Accept"));
		
		UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
		source.registerCorsConfiguration("/**", config);
		return source;
	}


	@Bean
	public FilterRegistrationBean<CorsFilter> corsFilter(){
		FilterRegistrationBean<CorsFilter> bean = new FilterRegistrationBean<CorsFilter>(new CorsFilter(corsConfigurationSource()));
		bean.setOrder(Ordered.HIGHEST_PRECEDENCE);
		return bean;
	}

	/**
	 * Prevents Spring Boot from auto-registering ModuleAccessFilter as a servlet filter.
	 * The filter is already registered in the Spring Security filter chain via addFilterAfter(),
	 * so we disable the automatic registration to avoid it running twice (once outside the
	 * security chain where authentication context may not be available).
	 */
	@Bean
	public FilterRegistrationBean<ModuleAccessFilter> moduleAccessFilterRegistration() {
		FilterRegistrationBean<ModuleAccessFilter> registration = new FilterRegistrationBean<>(moduleAccessFilter);
		registration.setEnabled(false);
		return registration;
	}

	/**
	 * Prevents Spring Boot from auto-registering SupervisorAccessFilter as a servlet filter.
	 * The filter is already registered in the Spring Security filter chain via addFilterAfter(),
	 * so we disable the automatic registration to avoid it running twice.
	 */
	@Bean
	public FilterRegistrationBean<SupervisorAccessFilter> supervisorAccessFilterRegistration() {
		FilterRegistrationBean<SupervisorAccessFilter> registration = new FilterRegistrationBean<>(supervisorAccessFilter);
		registration.setEnabled(false);
		return registration;
	}


}
