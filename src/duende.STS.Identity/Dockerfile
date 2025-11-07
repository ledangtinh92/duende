FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG TARGETARCH
WORKDIR /src
COPY ["src/duende.STS.Identity/duende.STS.Identity.csproj", "src/duende.STS.Identity/"]
COPY ["src/duende.Admin.EntityFramework.Shared/duende.Admin.EntityFramework.Shared.csproj", "src/duende.Admin.EntityFramework.Shared/"]
COPY ["src/duende.Shared/duende.Shared.csproj", "src/duende.Shared/"]
RUN dotnet restore -a $TARGETARCH "src/duende.STS.Identity/duende.STS.Identity.csproj"
COPY . .
WORKDIR "/src/src/duende.STS.Identity"
RUN dotnet build -a $TARGETARCH "duende.STS.Identity.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -a $TARGETARCH "duende.STS.Identity.csproj" -c Release --no-restore -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
ENTRYPOINT ["dotnet", "duende.STS.Identity.dll"]