package com.discord.bot.nitrado.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.DefaultUriBuilderFactory;

@Configuration
public class NitradoRestTemplateConfig {

    @Bean("nitradoRestTemplate")
    public RestTemplate nitradoRestTemplate(NitradoConfigProperties config) {
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(config.getConnectTimeoutMs());
        factory.setReadTimeout(config.getReadTimeoutMs());

        var restTemplate = new RestTemplate(factory);
        restTemplate.setUriTemplateHandler(
                new DefaultUriBuilderFactory(config.getBaseUrl()));
        return restTemplate;
    }
}
